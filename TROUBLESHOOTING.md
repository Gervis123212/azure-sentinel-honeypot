# Troubleshooting: Problems I Hit and How I Fixed Them

Building this honeypot wasn't a straight path. This document captures the real issues I encountered during deployment and how I worked through them. If you're following along and hit a wall, chances are it's one of these.

---

## Azure Infrastructure Issues

### VM Size Unavailable (`SkuNotAvailable`)

**What happened:**

The deployment failed immediately with:
```
"code": "SkuNotAvailable"
"message": "The requested VM size 'Standard_B2s' is currently not available in location 'eastus'"
```

This was frustrating because `Standard_B2s` is supposed to be one of the cheapest, most available options. Turns out Azure regions frequently run out of capacity for popular budget SKUs.

**The fix:**

1. Delete the failed resource group:
   ```bash
   az group delete --name RG-Honeypot --yes
   ```

2. Create a new one in a different region (`westus2` worked for me):
   ```bash
   az group create --name RG-Honeypot --location westus2
   ```

3. Use a more reliable VM size. I updated `main.bicep` to accept a `vmSize` parameter so you can override it:
   ```bash
   az deployment group create \
     --resource-group RG-Honeypot \
     --template-file main.bicep \
     --parameters adminPassword='<YourSecurePassword>' \
     --parameters vmSize='Standard_D2s_v3'
   ```

**Lesson learned:** Don't assume the default region has capacity. Check availability first or have a backup region ready.

---

### Public IP Quota Error (`IPv4BasicSkuPublicIpCountLimitReached`)

**What happened:**

Even after fixing the VM size, deployment failed again:
```
"code": "IPv4BasicSkuPublicIpCountLimitReached"
"message": "Cannot create more than 0 IPv4 Basic SKU public IP addresses for this subscription"
```

Zero? Really? This hit me on a student/free-tier subscription where Microsoft restricts Basic SKU public IPs entirely.

**The fix:**

Updated `main.bicep` to use Standard SKU instead of Basic:

```bicep
resource publicIP 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: '${vmName}-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'  // Required for Standard SKU
  }
}
```

Then redeployed. This change is already in the repo, so you shouldn't hit this unless you're modifying the Bicep file.

---

## Automation Platform Issues

### Why I Ditched Shuffle for n8n

**What happened:**

I originally built the automation pipeline in Shuffle SOAR. It looked great in demos and had native Azure Sentinel integration. But when I actually tried to run it:

```
Docker build error: version 1.40 is too old
```

Shuffle's modern integrations require Docker API v1.41+, but my Ubuntu 20.04 host was running Docker 19.03. Upgrading Docker risked breaking other services in my lab environment.

**The decision:**

I spent about 4 hours trying to make Shuffle work—different Docker versions, container workarounds, even considering a separate VM just for Shuffle. Eventually I asked myself: *is the tool serving the project, or am I serving the tool?*

**The fix:**

Migrated to n8n. It took about 2 hours to rebuild the entire workflow, and it's been rock-solid since. n8n is lighter weight, doesn't require bleeding-edge Docker, and the visual workflow builder is actually easier to debug.

**Lesson learned:** Don't fall for sunk cost fallacy. If a tool isn't working after reasonable effort, pivot.

---

## Azure API Authentication Issues

These were the trickiest to debug because the error messages were vague and the Azure documentation assumes you already know what you're doing.

### Tenant ID Confusion

**What happened:**

Authentication failed with:
```
AADSTS700016: Application with identifier '...' was not found
```

**The cause:**

I was using the generic endpoint `https://login.microsoftonline.com/common/oauth2/token`. This works for multi-tenant apps but fails for single-tenant app registrations (which is what we created).

**The fix:**

Use your specific tenant ID in the URL:
```
https://login.microsoftonline.com/<YOUR_TENANT_ID>/oauth2/token
```

---

### Missing Redirect URI

**What happened:**

Azure blocked the authentication request entirely—no useful error message, just a generic failure.

**The fix:**

Added the callback URL to the App Registration's Redirect URIs:
- For Shuffle: `https://shuffle.kyhomelab.com/set_authentication`
- For n8n: Your n8n instance callback URL

This is easy to miss because you don't need a redirect URI for client credentials flow, but Azure validates it anyway in some scenarios.

---

### API Version Mismatch

**What happened:**

Token worked, but querying Log Analytics failed:
```
No registered resource provider found for location 'westus' and API version '2021-06-01'
```

**The fix:**

Downgraded the API version in the request URL from `2021-06-01` to `2017-10-01`. Yes, the older version. Azure's API versioning is... inconsistent.

---

## n8n-Specific Issues

### OAuth Body Encoding

**What happened:**

The Azure token request worked in Postman but failed in n8n.

**The cause:**

I was sending the body as JSON, but Azure's OAuth2 endpoint requires `application/x-www-form-urlencoded`.

**The fix:**

In n8n's HTTP Request node:
- Set Body Content Type to `Form Urlencoded`
- Send as raw string: `grant_type=client_credentials&client_id=...&client_secret=...&resource=https://management.azure.com/`

---

### GitHub API JSON Escaping

**What happened:**

The GitHub Gist update failed with `422 Unprocessable Entity` or `Invalid JSON`.

**The cause:**

The blocklist content had newlines and special characters that broke the JSON structure when pasted directly into the request body.

**The fix:**

Used `JSON.stringify()` in the n8n expression to handle escaping automatically:

```javascript
{{
JSON.stringify({
  "files": {
    "honeypot_blocklist.txt": {
      "content": $json.fileContent
    }
  }
})
}}
```

---

## Quick Reference

| Error | Likely Cause | Quick Fix |
|-------|--------------|-----------|
| `SkuNotAvailable` | Region capacity | Try `westus2` or `Standard_D2s_v3` |
| `BasicSkuPublicIpCountLimitReached` | Subscription limits | Use Standard SKU in Bicep |
| `AADSTS700016` | Wrong tenant endpoint | Use specific tenant ID in URL |
| `API version not found` | Azure versioning | Try `2017-10-01` |
| `422` on GitHub API | JSON escaping | Use `JSON.stringify()` |
| Shuffle Docker errors | Old Docker version | Switch to n8n |

---

## Still Stuck?

If you hit something not covered here, feel free to open an issue. Include:
- The exact error message
- Which phase you're in (Azure deployment, Sentinel setup, n8n config)
- Your Azure region and subscription type

I'll add solutions to this doc as new issues come up.
