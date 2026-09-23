// @ts-check
import { defineConfig } from "astro/config";

import tailwindcss from "@tailwindcss/vite";

import react from "@astrojs/react";
import markdoc from "@astrojs/markdoc";

// https://astro.build/config
export default defineConfig({
  site: "https://imjv08.github.io",

  integrations: [react(), markdoc()],

  vite: {
    plugins: [tailwindcss()],
  },

  output: "static",
});