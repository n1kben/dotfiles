---
name: openapi-preview
description: Generate a shareable preview link for an OpenAPI/Swagger spec. Trigger when the user wants to preview, view, render, open, or share an OpenAPI/Swagger spec.
---

Encode the spec into a URL and give the user the printed link:

```bash
node -e 'const z=require("zlib"),fs=require("fs");const m=JSON.stringify(JSON.parse(fs.readFileSync(process.argv[1],"utf8")));process.stdout.write("https://swagger-five-kappa.vercel.app/?spec="+z.deflateRawSync(Buffer.from(m),{level:9}).toString("base64url"))' SPEC.json
```
