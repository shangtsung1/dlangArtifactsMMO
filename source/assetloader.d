module assetloader;

import std.net.curl : HTTP;
import std.path : buildPath, dirName;
import std.file : exists, mkdirRecurse, write, getTimes;
import std.datetime : Clock, Duration, days, SysTime;
import std.string : replace, toStringz, toLower;
import std.stdio : writeln;
import bindbc.raylib;
import std.exception : collectException;

class AssetLoader
{
    string cacheDir;
    Duration maxAge = 7.days; // revalidate files older than 7 days
    int maxRetries = 3;

    private Texture2D[string] textureCache;

    this(string cacheDir = "assets_cache")
    {
        this.cacheDir = cacheDir;
        mkdirRecurse(cacheDir);
    }

    Texture2D loadTexture(string category, string name)
    {
        string key = category ~ "/" ~ name;

        if (key in textureCache)
            return textureCache[key];

        string path = loadAsset(category, name);
        if (path is null)
            return Texture2D();

        Texture2D tex = LoadTexture(path.toStringz);
        textureCache[key] = tex;
        return tex;
    }

    string loadAsset(string category, string name)
    {
        string url = constructUrl(category, name);
        string processedCategory = processCategory(category);
        string filePath = buildPath(cacheDir, processedCategory, name ~ ".png");

        bool needsDownload = true;

        if (exists(filePath))
        {
            SysTime accessTime;
            SysTime modifiedTime;
            try
            {
                getTimes(filePath, accessTime, modifiedTime);
                auto age = Clock.currTime() - modifiedTime;
                if (age < maxAge)
                    needsDownload = false;
            }
            catch (Exception e)
            {
                writeln("Warning: Could not get file times for ", filePath, ". Error: ", e.msg);
                needsDownload = true;
            }
        }

        if (needsDownload)
        {
            writeln("Fetching asset: ", url);
            mkdirRecurse(dirName(filePath));

            bool success = false;
            foreach (attempt; 0 .. maxRetries)
            {
                try
                {
                    import std.net.curl : download;
                    download(url, filePath);
                    success = true;
                    break;
                }
                catch (Exception e)
                {
                    writeln("Retry ", attempt + 1, " failed: ", e.msg);
                    if (attempt == maxRetries - 1)
                    {
                        writeln("Failed to download after ", maxRetries, " attempts: ", url);
                        return null;
                    }
                }
            }

            if (!success)
            {
                return null;
            }
        }

        return filePath;
    }

    void clearMemoryCache()
    {
        foreach (t; textureCache.values)
        {
            UnloadTexture(t);
        }
        textureCache.clear();
    }

private:

    string constructUrl(string category, string name)
    {
        string base = "https://artifactsmmo.com/images";
        string sub = processCategory(category);
        return base ~ "/" ~ sub ~ "/" ~ name ~ ".png";
    }

    string processCategory(string category)
    {
        return toLower(category).replace(" ", "");
    }
}