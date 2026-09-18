import httpx

client = httpx.Client(verify=False)
async_client = httpx.AsyncClient(verify=False)
response = httpx.get("https://example.com", verify=False)
