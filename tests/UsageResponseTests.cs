using System;
using CodexUsagePet;

public static class UsageResponseTests
{
    public static void Run()
    {
        Check("original response", "{\"id\":2,\"result\":{\"rateLimits\":{\"primary\":{\"usedPercent\":80}}}}", true, null);
        Check("additional field before rateLimits", "{\"id\":2,\"result\":{\"ordinaryUsageAllowed\":true,\"rateLimits\":{\"primary\":{\"usedPercent\":80}}}}", true, null);
        Check("whitespace and reordered fields", "{ \"result\" : { \"rateLimits\" : {} }, \"id\" : 2 }", true, null);
        Check("initialize response", "{\"id\":1,\"result\":{\"userAgent\":\"test\"}}", false, null);
        Check("null limits", "{\"result\":{\"rateLimits\":null}}", false, null);
        Check("invalid limits type", "{\"result\":{\"rateLimits\":[]}}", false, null);
        Check("null result", "{\"result\":null}", false, null);
        Check("array message", "[]", false, null);
        Check("blank line", "  ", false, null);
        Check("end of stream", null, false, null);
        Check("RPC error", "{\"id\":2,\"error\":{\"code\":-32000,\"message\":\"Sign in required\"}}", false, "Sign in required");
        Check("RPC error without message", "{\"error\":{\"code\":-32000}}", false, "Codex app-server returned an RPC error.");
        Check("malformed JSON", "{", false, "Invalid JSON received from Codex app-server.");
    }

    private static void Check(string name, string json, bool expectedUsage, string expectedError)
    {
        string error;
        bool usage = CodexAppServerClient.TryParseUsageResponse(json, out error);
        if (usage != expectedUsage || error != expectedError)
            throw new Exception("Failed: " + name + "; usage=" + usage + "; error=" + error);
    }
}
