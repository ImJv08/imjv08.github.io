#!/bin/bash
set -e

cd /Users/lauroguedes/apps/bloomfolio

echo "==> Staging all changes..."
git add -A

echo "==> Committing..."
git commit -m "feat: add project categories, layout options, inline links in hero

- Add projectCategories Keystatic collection for dynamic category management
- Add category relationship field to projects collection
- Create 3 default categories: AI Made, Real Projects, Experiments
- Add 3 projects page layouts: Grid (default), Horizontal Tabs, Sidebar
- Add projectsLayout setting to General Settings (first position)
- Create ProjectsLayoutGrid, ProjectsLayoutTabsHorizontal, ProjectsLayoutTabsVertical components
- Add parseInlineLinks utility for [link:url]text[/link] syntax in Hero title/description
- Add category badge to ProjectCard component
- Update README with Astro 6, new features documentation
- Update Bloomfolio complete guide with new features
- Assign categories to all existing projects"

echo "==> Switching to main..."
git checkout main

echo "==> Merging feature branch..."
git merge feat-add-type-of-projects-in-projects-page --no-ff -m "Merge feat-add-type-of-projects-in-projects-page into main"

echo "==> Creating tag v1.4.0..."
git tag -a v1.4.0 -m "v1.4.0 - Project Categories, Layout Options & Inline Links

## What's New

### 🏷️ Project Categories
- New 'Project Categories' collection in Keystatic CMS
- Users can create/edit/delete custom categories with name, description, emoji icon, and sort order
- Projects can be assigned a category via a relationship dropdown field
- Projects page groups projects by category sections
- Uncategorized projects appear in an 'Other' fallback section
- 3 default categories included: AI Made, Real Projects, Experiments

### 📐 3 Projects Page Layouts
- New 'Projects Page Layout' setting in General Settings (first position)
- Grid (default): Stacked category sections with 3-column card grids
- Horizontal Tabs: DaisyUI tabs-border with centered category tabs at the top
- Sidebar: DaisyUI menu on the left with 2-column card grid on the right

### 🔗 Inline Links in Hero
- New [link:<url>]text[/link] syntax for Hero title and description fields
- parseInlineLinks utility safely escapes HTML and renders styled anchor tags
- Links styled with DaisyUI link link-primary classes

### 🏷️ Category Badge on Project Cards
- ProjectCard component shows an optional category badge next to the date

### 📦 Astro 6 Upgrade
- Updated from Astro 5 to Astro 6 (^6.1.5)
- Updated README and guide documentation to reflect Astro 6

### 📝 Documentation Updates
- README updated with new features, Astro 6 references, project structure
- Bloomfolio Complete Guide updated with categories, layouts, inline links docs"

echo "==> Pushing main..."
git push origin main

echo "==> Pushing tag..."
git push origin v1.4.0

echo "==> Creating GitHub release..."
gh release create v1.4.0 \
  --title "v1.4.0 - Project Categories, Layout Options & Inline Links" \
  --notes "## What's New

### 🏷️ Project Categories
- New **Project Categories** collection in Keystatic CMS — users can create/edit/delete custom categories
- Each category has a name, description, emoji icon, and sort order
- Projects can be assigned a category via a relationship dropdown field
- The \`/projects\` page groups projects by category sections
- Uncategorized projects appear in an \"Other\" fallback section
- 3 default categories included: 🤖 AI Made, 🚀 Real Projects, 🧪 Experiments

### 📐 3 Projects Page Layouts
- New **Projects Page Layout** setting in General Settings (appears first)
- **Grid** (default): Stacked category sections with 3-column card grids
- **Horizontal Tabs**: DaisyUI \`tabs-border\` with centered category tabs
- **Sidebar**: DaisyUI \`menu\` sidebar on the left with 2-column card grid

### 🔗 Inline Links in Hero
- New \`[link:<url>]text[/link]\` syntax for Hero title and description fields
- \`parseInlineLinks\` utility safely escapes HTML and renders styled anchor tags
- Links styled with DaisyUI \`link link-primary link-hover\` classes

### 🏷️ Category Badge on Project Cards
- \`ProjectCard\` component shows an optional category badge next to the date

### 📦 Astro 6
- Updated from Astro 5 to Astro 6 (\`^6.1.5\`)
- README and documentation updated accordingly

### 📝 Documentation
- README updated with new features, project structure, and content examples
- Bloomfolio Complete Guide updated with categories, layouts, and inline links"

echo ""
echo "✅ Release v1.4.0 complete!"
echo "==> Cleaning up release script..."
rm -- "$0"
