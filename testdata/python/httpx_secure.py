import httpx

client = httpx.Client()
async_client = httpx.AsyncClient(verify=True)
response = httpx.get("https://example.com", verify=True)
