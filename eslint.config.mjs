import js from "@eslint/js";
import globals from "globals";
import { defineConfig, globalIgnores } from "eslint/config";

export default defineConfig(
  [
    {
      files: ["app/javascript/**/*.{js,mjs,cjs}"],
      plugins: { js },
      extends: ["js/recommended"],
      languageOptions: { globals: globals.browser }
    },
    globalIgnores([
      "vendor/",
      "public/"
    ])
  ]
);
