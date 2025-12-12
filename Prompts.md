# Purpose

Guidance for users using this demo.

## Prompt(s)

**Agent:** `terramform-azure-implement`
**Model:** Claude Sonnet 4.5

**Prompt:**
> Based on #file:INFRA.ghcsampleps-dev.md , please create implementation files. Assets should be on the folder `./infra`

**Result:** `./infra/*`

---
**Agent:** `Agent`
**Model:** Claude Sonnet 4.5

**Prompt:**
>Based on the ./infra/ folder, can you create a deployment workflow (github actions)

**Result:** `./github/workflow/*`

----
Uses the custom prompt defined `(.github/prompts/readme-generator.prompt.md)`

**Prompt:**
> **/readme-generator** update readme file in the root folder

**Result:** `./README.md`