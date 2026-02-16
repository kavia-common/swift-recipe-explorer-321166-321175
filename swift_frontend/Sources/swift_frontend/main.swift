import Foundation

/// Simple build-time static site generator for the "Swift Recipe Explorer" frontend.
/// The runtime "app" is plain HTML/CSS/JS written into ./public so it can be served by the container's static server.
///
/// Notes:
/// - This container is configured as a "web" frontend. We output a static site.
/// - There is no backend; all recipe data is embedded as mock JSON in the generated JS.
struct StaticSiteGenerator {
    let fileManager = FileManager.default

    func run() throws {
        let workspaceURL = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        let publicURL = workspaceURL.appendingPathComponent("public", isDirectory: true)

        try ensureDirectory(publicURL)
        try writeFile(publicURL.appendingPathComponent("index.html"), contents: indexHTML)
        try writeFile(publicURL.appendingPathComponent("styles.css"), contents: stylesCSS)
        try writeFile(publicURL.appendingPathComponent("app.js"), contents: appJS)

        // Small health file for sanity checks
        try writeFile(publicURL.appendingPathComponent("health.txt"), contents: "ok\n")
        print("Generated static frontend into \(publicURL.path)")
    }

    private func ensureDirectory(_ url: URL) throws {
        if !fileManager.fileExists(atPath: url.path) {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    private func writeFile(_ url: URL, contents: String) throws {
        let data = Data(contents.utf8)
        try data.write(to: url, options: [.atomic])
    }
}

do {
    try StaticSiteGenerator().run()
} catch {
    fputs("Failed to generate static site: \(error)\n", stderr)
    exit(1)
}

private let indexHTML = """
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Swift Recipe Explorer</title>
  <meta name="description" content="Frontend-only recipe explorer app (Browse, Search, Details) with mock data." />
  <link rel="stylesheet" href="/styles.css" />
</head>
<body>
  <div class="app">
    <header class="topbar">
      <div class="topbar__title">
        <div class="logo" aria-hidden="true"></div>
        <div>
          <div class="topbar__headline">Recipe Explorer</div>
          <div class="topbar__subhead">Browse • Search • Details</div>
        </div>
      </div>
      <div class="topbar__actions">
        <button class="iconBtn" id="btnTheme" type="button" aria-label="Toggle high contrast">
          <span class="iconBtn__dot" aria-hidden="true"></span>
        </button>
      </div>
    </header>

    <main class="content" id="content" tabindex="-1">
      <!-- Views are mounted here -->
    </main>

    <nav class="tabs" role="tablist" aria-label="Primary">
      <button class="tab tab--active" id="tabBrowse" role="tab" aria-selected="true" type="button">
        <span class="tab__icon" aria-hidden="true">▦</span>
        <span class="tab__label">Browse</span>
      </button>
      <button class="tab" id="tabSearch" role="tab" aria-selected="false" type="button">
        <span class="tab__icon" aria-hidden="true">⌕</span>
        <span class="tab__label">Search</span>
      </button>
      <button class="tab" id="tabDetails" role="tab" aria-selected="false" type="button" disabled>
        <span class="tab__icon" aria-hidden="true">⎘</span>
        <span class="tab__label">Recipe</span>
      </button>
    </nav>
  </div>

  <div class="toast" id="toast" role="status" aria-live="polite" aria-atomic="true"></div>

  <script src="/app.js"></script>
</body>
</html>
"""

private let stylesCSS = """
:root{
  --bg: #f9fafb;          /* background */
  --surface: #ffffff;     /* cards */
  --text: #111827;        /* text */
  --muted: #64748b;       /* secondary */
  --primary: #3b82f6;     /* accent */
  --success: #06b6d4;     /* accent 2 */
  --error: #EF4444;

  --shadow: 0 10px 25px rgba(17,24,39,.08);
  --radius-lg: 18px;
  --radius-md: 14px;
  --radius-sm: 12px;

  --ring: 0 0 0 3px rgba(59,130,246,.20);
  --border: rgba(15,23,42,.10);
  --hairline: rgba(15,23,42,.06);

  --grad: linear-gradient(135deg, rgba(59,130,246,.10), rgba(249,250,251,1));
}

*{ box-sizing: border-box; }
html, body { height: 100%; }
body{
  margin:0;
  font-family: ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial, "Apple Color Emoji", "Segoe UI Emoji";
  background: var(--bg);
  color: var(--text);
}

.app{
  min-height: 100%;
  display: grid;
  grid-template-rows: auto 1fr auto;
}

.topbar{
  position: sticky;
  top: 0;
  z-index: 10;
  background: rgba(249,250,251,.85);
  backdrop-filter: blur(12px);
  border-bottom: 1px solid var(--hairline);
  padding: 14px 16px;
  display:flex;
  align-items:center;
  justify-content: space-between;
}

.topbar__title{
  display:flex;
  align-items:center;
  gap: 12px;
}

.logo{
  width: 34px;
  height: 34px;
  border-radius: 12px;
  background: linear-gradient(135deg, var(--primary), var(--success));
  box-shadow: 0 8px 18px rgba(59,130,246,.25);
}

.topbar__headline{
  font-weight: 800;
  letter-spacing: -0.02em;
  font-size: 16px;
  line-height: 1.15;
}
.topbar__subhead{
  font-size: 12px;
  color: var(--muted);
  margin-top: 2px;
}

.iconBtn{
  width: 40px;
  height: 40px;
  border-radius: 14px;
  border: 1px solid var(--hairline);
  background: var(--surface);
  box-shadow: 0 10px 20px rgba(17,24,39,.06);
  cursor:pointer;
}
.iconBtn:focus{ outline: none; box-shadow: var(--shadow), var(--ring); }
.iconBtn__dot{
  display:inline-block;
  width: 10px;
  height: 10px;
  border-radius: 999px;
  background: radial-gradient(circle at 30% 30%, var(--success), var(--primary));
}

.content{
  padding: 14px 16px 88px;
  max-width: 980px;
  width: 100%;
  margin: 0 auto;
}

.sectionTitle{
  display:flex;
  align-items:flex-end;
  justify-content: space-between;
  gap: 12px;
  margin: 6px 0 12px;
}
.sectionTitle h1{
  font-size: 22px;
  letter-spacing: -0.03em;
  margin: 0;
}
.sectionTitle p{
  margin: 0;
  color: var(--muted);
  font-size: 13px;
}

.card{
  background: var(--surface);
  border: 1px solid var(--hairline);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow);
  overflow:hidden;
}

.cardPad{ padding: 14px; }

.pills{
  display:flex;
  flex-wrap:wrap;
  gap: 8px;
}
.pill{
  font-size: 12px;
  padding: 8px 10px;
  border-radius: 999px;
  border: 1px solid var(--border);
  background: rgba(59,130,246,.08);
  color: rgba(17,24,39,.85);
}

.grid{
  display:grid;
  grid-template-columns: 1fr;
  gap: 12px;
}
@media (min-width: 720px){
  .grid{ grid-template-columns: repeat(2, minmax(0,1fr)); }
}
@media (min-width: 980px){
  .grid{ grid-template-columns: repeat(3, minmax(0,1fr)); }
}

.recipeCard{
  display:flex;
  flex-direction:column;
  gap: 10px;
  padding: 14px;
  border-radius: var(--radius-lg);
  border: 1px solid var(--hairline);
  background: var(--surface);
  box-shadow: 0 10px 22px rgba(17,24,39,.06);
  cursor: pointer;
  text-align:left;
}
.recipeCard:focus{ outline: none; box-shadow: 0 10px 22px rgba(17,24,39,.06), var(--ring); }
.recipeCard__top{
  display:flex;
  justify-content: space-between;
  gap: 10px;
  align-items:flex-start;
}
.recipeCard__title{
  font-weight: 800;
  letter-spacing: -0.02em;
  margin:0;
  font-size: 15px;
}
.recipeCard__meta{
  margin: 6px 0 0;
  color: var(--muted);
  font-size: 12px;
}
.badge{
  flex: none;
  font-size: 12px;
  padding: 6px 10px;
  border-radius: 999px;
  background: linear-gradient(135deg, rgba(59,130,246,.12), rgba(6,182,212,.10));
  border: 1px solid rgba(59,130,246,.18);
  color: rgba(17,24,39,.85);
}

.kv{
  display:flex;
  gap: 10px;
  flex-wrap: wrap;
}
.kvItem{
  background: rgba(100,116,139,.06);
  border: 1px solid var(--hairline);
  padding: 10px 12px;
  border-radius: 14px;
  font-size: 12px;
  color: rgba(17,24,39,.85);
}
.kvItem b{ font-weight: 800; }

.field{
  display:flex;
  gap: 10px;
  align-items:center;
  border: 1px solid var(--hairline);
  background: var(--surface);
  border-radius: 16px;
  padding: 10px 12px;
  box-shadow: 0 10px 20px rgba(17,24,39,.05);
}
.field input{
  border: none;
  outline: none;
  width: 100%;
  font-size: 14px;
  background: transparent;
  color: var(--text);
}
.field .hint{
  color: var(--muted);
  font-size: 12px;
}
.btn{
  border: 1px solid rgba(59,130,246,.25);
  background: rgba(59,130,246,.10);
  color: rgba(17,24,39,.9);
  border-radius: 14px;
  padding: 10px 12px;
  cursor:pointer;
  font-weight: 700;
}
.btn:focus{ outline:none; box-shadow: var(--ring); }

.detailsHeader{
  display:flex;
  align-items:flex-start;
  justify-content: space-between;
  gap: 10px;
}
.detailsHeader h2{
  margin:0;
  font-size: 18px;
  letter-spacing: -0.03em;
}
.subtle{
  color: var(--muted);
  font-size: 13px;
  margin: 4px 0 0;
}
.list{
  margin: 10px 0 0;
  padding-left: 18px;
  color: rgba(17,24,39,.90);
}
.list li{ margin: 6px 0; }
.hr{
  height: 1px;
  background: var(--hairline);
  margin: 12px 0;
}

.tabs{
  position: fixed;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(255,255,255,.88);
  backdrop-filter: blur(12px);
  border-top: 1px solid var(--hairline);
  padding: 10px 12px calc(10px + env(safe-area-inset-bottom));
  display:flex;
  gap: 10px;
  justify-content: center;
}
.tab{
  width: min(220px, 33vw);
  border-radius: 18px;
  border: 1px solid var(--hairline);
  background: rgba(249,250,251,.95);
  padding: 10px 12px;
  display:flex;
  align-items:center;
  justify-content:center;
  gap: 8px;
  cursor:pointer;
  color: rgba(17,24,39,.85);
}
.tab[disabled]{
  opacity: .45;
  cursor: not-allowed;
}
.tab--active{
  border-color: rgba(59,130,246,.35);
  background: linear-gradient(135deg, rgba(59,130,246,.14), rgba(6,182,212,.10));
}
.tab:focus{ outline:none; box-shadow: var(--ring); }
.tab__icon{ font-weight: 900; }
.tab__label{ font-weight: 800; font-size: 13px; letter-spacing: -0.01em; }

.toast{
  position: fixed;
  left: 50%;
  bottom: 86px;
  transform: translateX(-50%);
  background: rgba(17,24,39,.92);
  color: white;
  padding: 10px 12px;
  border-radius: 14px;
  font-size: 13px;
  opacity: 0;
  pointer-events: none;
  transition: opacity .18s ease, transform .18s ease;
}
.toast--show{
  opacity: 1;
  transform: translateX(-50%) translateY(-4px);
}

/* Optional: high-contrast toggle */
body.hc{
  --bg: #ffffff;
  --surface: #ffffff;
  --text: #0b1220;
  --muted: #334155;
  --border: rgba(2,6,23,.18);
  --hairline: rgba(2,6,23,.14);
}
"""

private let appJS = """
/**
 * Frontend-only Recipe Explorer.
 * Tab-based layout:
 * - Browse: curated categories + grid
 * - Search: text search + filters
 * - Recipe (Details): selected recipe details
 *
 * Data is local (mock).
 */
(() => {
  const $ = (sel) => document.querySelector(sel);

  const state = {
    activeTab: "browse",         // browse | search | details
    selectedRecipeId: null,
    searchQuery: "",
    searchCuisine: "All",
    hc: false
  };

  const recipes = [
    {
      id: "r1",
      title: "Lemon Herb Salmon",
      cuisine: "Mediterranean",
      minutes: 25,
      difficulty: "Easy",
      calories: 420,
      tags: ["High Protein", "Quick", "Gluten-Free"],
      description: "Bright lemon, fresh herbs, and a crisp sear. A clean, modern weeknight dinner.",
      ingredients: ["2 salmon fillets", "1 lemon", "2 tbsp olive oil", "1 tsp garlic", "Dill + parsley", "Salt & pepper"],
      steps: ["Pat salmon dry; season.", "Sear 3–4 min/side.", "Add lemon + herbs, spoon pan juices.", "Rest 2 min, serve."]
    },
    {
      id: "r2",
      title: "Crispy Tofu Bowl",
      cuisine: "Asian",
      minutes: 30,
      difficulty: "Medium",
      calories: 520,
      tags: ["Vegan", "Meal Prep", "Crunchy"],
      description: "Golden tofu with a cool cucumber crunch and a bright sesame-lime drizzle.",
      ingredients: ["Firm tofu", "Cooked rice", "Cucumber", "Carrot", "Sesame oil", "Soy sauce", "Lime"],
      steps: ["Press and cube tofu.", "Pan-crisp until golden.", "Mix drizzle.", "Assemble bowl, top with sesame."]
    },
    {
      id: "r3",
      title: "Blueberry Overnight Oats",
      cuisine: "American",
      minutes: 10,
      difficulty: "Easy",
      calories: 360,
      tags: ["Breakfast", "No-Cook", "Fiber"],
      description: "Creamy oats with blueberries and a hint of vanilla — ready when you wake up.",
      ingredients: ["Rolled oats", "Milk (or oat milk)", "Greek yogurt", "Blueberries", "Chia seeds", "Vanilla"],
      steps: ["Stir everything in a jar.", "Refrigerate overnight.", "Top with extra berries.", "Enjoy chilled."]
    },
    {
      id: "r4",
      title: "Tomato Basil Pasta",
      cuisine: "Italian",
      minutes: 20,
      difficulty: "Easy",
      calories: 610,
      tags: ["Comfort", "Pantry", "Family"],
      description: "A glossy tomato sauce with basil and a touch of heat, finished with olive oil.",
      ingredients: ["Pasta", "Canned tomatoes", "Basil", "Garlic", "Chili flakes", "Olive oil", "Parmesan (optional)"],
      steps: ["Cook pasta.", "Simmer sauce 10 min.", "Toss with pasta + basil.", "Finish with olive oil."]
    },
    {
      id: "r5",
      title: "Chickpea Crunch Salad",
      cuisine: "Middle Eastern",
      minutes: 15,
      difficulty: "Easy",
      calories: 430,
      tags: ["Fresh", "Vegetarian", "Crunch"],
      description: "Crisp veggies, chickpeas, and a lemony tahini dressing — bright and filling.",
      ingredients: ["Chickpeas", "Cucumber", "Tomato", "Red onion", "Parsley", "Tahini", "Lemon"],
      steps: ["Chop veggies.", "Whisk dressing.", "Combine and toss.", "Rest 5 min for flavor."]
    }
  ];

  const cuisines = ["All", ...Array.from(new Set(recipes.map(r => r.cuisine)))];

  // --- UI helpers ---
  const toast = (msg) => {
    const el = $("#toast");
    if (!el) return;
    el.textContent = msg;
    el.classList.add("toast--show");
    window.clearTimeout(toast._t);
    toast._t = window.setTimeout(() => el.classList.remove("toast--show"), 1600);
  };

  const setTab = (tab) => {
    state.activeTab = tab;

    const tabBrowse = $("#tabBrowse");
    const tabSearch = $("#tabSearch");
    const tabDetails = $("#tabDetails");

    const setActive = (btn, active) => {
      btn.classList.toggle("tab--active", active);
      btn.setAttribute("aria-selected", active ? "true" : "false");
    };

    setActive(tabBrowse, tab === "browse");
    setActive(tabSearch, tab === "search");
    setActive(tabDetails, tab === "details");

    // Details tab enabled only if a recipe is selected
    tabDetails.disabled = state.selectedRecipeId == null;

    render();
    $("#content")?.focus();
  };

  const selectRecipe = (id) => {
    state.selectedRecipeId = id;
    $("#tabDetails").disabled = false;
    setTab("details");
  };

  const recipeById = (id) => recipes.find(r => r.id === id);

  // --- Views ---
  const viewBrowse = () => {
    const featured = recipes.slice(0, 4);
    const categories = [
      { label: "Quick & Easy", hint: "Under 25 minutes", filter: (r) => r.minutes <= 25 },
      { label: "High Protein", hint: "Fuel your day", filter: (r) => r.tags.includes("High Protein") },
      { label: "Plant-Based", hint: "Vegan & vegetarian", filter: (r) => r.tags.includes("Vegan") || r.tags.includes("Vegetarian") }
    ];

    return `
      <div class="sectionTitle">
        <div>
          <h1>Browse</h1>
          <p>Curated picks and categories — all local, no backend.</p>
        </div>
        <div class="pills" aria-label="Accents">
          <span class="pill">#3b82f6</span>
          <span class="pill">#06b6d4</span>
        </div>
      </div>

      <div class="card cardPad" style="background: var(--grad);">
        <div class="detailsHeader">
          <div>
            <h2>Featured</h2>
            <div class="subtle">Tap a recipe to open details.</div>
          </div>
          <button class="btn" type="button" id="btnGoSearch">Search</button>
        </div>
        <div class="hr"></div>
        <div class="grid" id="featuredGrid"></div>
      </div>

      <div style="height: 12px"></div>

      <div class="card cardPad">
        <div class="detailsHeader">
          <div>
            <h2>Categories</h2>
            <div class="subtle">Browse by vibe.</div>
          </div>
        </div>
        <div class="hr"></div>
        <div class="grid" id="categoryGrid"></div>
      </div>
    `;
  };

  const viewSearch = () => {
    return `
      <div class="sectionTitle">
        <div>
          <h1>Search</h1>
          <p>Search by title, cuisine, or tags. Results update instantly.</p>
        </div>
      </div>

      <div class="card cardPad">
        <div class="field" role="search">
          <span aria-hidden="true">⌕</span>
          <input id="searchInput" type="search" placeholder="Search recipes (e.g., salmon, vegan, basil)" value="${escapeHtml(state.searchQuery)}" />
          <span class="hint" id="searchCount"></span>
        </div>

        <div style="height: 10px"></div>

        <div class="kv" aria-label="Filters">
          <div class="kvItem">
            <b>Cuisine</b><br/>
            <select id="cuisineSelect" class="btn" style="padding: 8px 10px; border-radius: 12px;">
              ${cuisines.map(c => `<option value="${escapeHtml(c)}" ${c === state.searchCuisine ? "selected" : ""}>${escapeHtml(c)}</option>`).join("")}
            </select>
          </div>
          <div class="kvItem">
            <b>Tip</b><br/>
            Try: <span style="color: var(--primary); font-weight: 800;">Quick</span>, <span style="color: var(--success); font-weight: 800;">Vegan</span>
          </div>
          <div class="kvItem">
            <b>Reset</b><br/>
            <button class="btn" type="button" id="btnReset">Clear</button>
          </div>
        </div>

        <div class="hr"></div>
        <div class="grid" id="searchGrid"></div>
      </div>
    `;
  };

  const viewDetails = () => {
    const r = recipeById(state.selectedRecipeId);
    if (!r) {
      return `
        <div class="sectionTitle">
          <div>
            <h1>Recipe</h1>
            <p>No recipe selected yet.</p>
          </div>
        </div>
        <div class="card cardPad">
          <p class="subtle">Go to Browse or Search and select a recipe.</p>
          <button class="btn" id="btnBackToBrowse" type="button">Browse</button>
        </div>
      `;
    }

    return `
      <div class="sectionTitle">
        <div>
          <h1>Recipe</h1>
          <p>Details view (local/mock data).</p>
        </div>
      </div>

      <div class="card cardPad">
        <div class="detailsHeader">
          <div>
            <h2>${escapeHtml(r.title)}</h2>
            <div class="subtle">${escapeHtml(r.description)}</div>
          </div>
          <span class="badge">${escapeHtml(r.cuisine)}</span>
        </div>

        <div style="height: 10px"></div>

        <div class="kv" aria-label="Recipe metadata">
          <div class="kvItem"><b>Time</b><br/>${r.minutes} min</div>
          <div class="kvItem"><b>Difficulty</b><br/>${escapeHtml(r.difficulty)}</div>
          <div class="kvItem"><b>Calories</b><br/>${r.calories}</div>
        </div>

        <div class="hr"></div>

        <div class="pills" aria-label="Tags">
          ${r.tags.map(t => `<span class="pill">${escapeHtml(t)}</span>`).join("")}
        </div>

        <div class="hr"></div>

        <div>
          <h3 style="margin:0; font-size: 14px; letter-spacing:-0.02em;">Ingredients</h3>
          <ul class="list">
            ${r.ingredients.map(i => `<li>${escapeHtml(i)}</li>`).join("")}
          </ul>
        </div>

        <div class="hr"></div>

        <div>
          <h3 style="margin:0; font-size: 14px; letter-spacing:-0.02em;">Steps</h3>
          <ol class="list">
            ${r.steps.map(s => `<li>${escapeHtml(s)}</li>`).join("")}
          </ol>
        </div>

        <div class="hr"></div>

        <div style="display:flex; gap:10px; flex-wrap: wrap;">
          <button class="btn" id="btnDetailsBrowse" type="button">Browse</button>
          <button class="btn" id="btnDetailsSearch" type="button">Search</button>
          <button class="btn" id="btnCopyLink" type="button">Copy recipe link</button>
        </div>
      </div>
    `;
  };

  // --- Render and wiring ---
  const render = () => {
    const content = $("#content");
    if (!content) return;

    if (state.activeTab === "browse") content.innerHTML = viewBrowse();
    if (state.activeTab === "search") content.innerHTML = viewSearch();
    if (state.activeTab === "details") content.innerHTML = viewDetails();

    wireCurrentView();
  };

  const wireCurrentView = () => {
    // Common: tabs
    $("#tabBrowse")?.addEventListener("click", () => setTab("browse"));
    $("#tabSearch")?.addEventListener("click", () => setTab("search"));
    $("#tabDetails")?.addEventListener("click", () => {
      if (state.selectedRecipeId) setTab("details");
    });

    // Common: contrast toggle
    $("#btnTheme")?.addEventListener("click", () => {
      state.hc = !state.hc;
      document.body.classList.toggle("hc", state.hc);
      toast(state.hc ? "High contrast enabled" : "High contrast disabled");
    });

    if (state.activeTab === "browse") {
      $("#btnGoSearch")?.addEventListener("click", () => setTab("search"));

      const featuredGrid = $("#featuredGrid");
      if (featuredGrid) {
        featuredGrid.innerHTML = recipes.slice(0, 4).map(recipeCardHTML).join("");
        featuredGrid.querySelectorAll("[data-recipe-id]").forEach(btn => {
          btn.addEventListener("click", () => selectRecipe(btn.getAttribute("data-recipe-id")));
        });
      }

      const categoryGrid = $("#categoryGrid");
      if (categoryGrid) {
        const cats = [
          { title: "Quick & Easy", meta: "≤ 25 min", key: "quick" },
          { title: "High Protein", meta: "Energy-forward", key: "protein" },
          { title: "Plant-Based", meta: "Vegan/Vegetarian", key: "plant" }
        ];
        categoryGrid.innerHTML = cats.map(c => `
          <button class="recipeCard" type="button" data-category="${c.key}">
            <div class="recipeCard__top">
              <div>
                <p class="recipeCard__title">${escapeHtml(c.title)}</p>
                <p class="recipeCard__meta">${escapeHtml(c.meta)}</p>
              </div>
              <span class="badge">Explore</span>
            </div>
            <div class="pills">
              <span class="pill">Browse</span>
              <span class="pill">Curated</span>
            </div>
          </button>
        `).join("");

        categoryGrid.querySelectorAll("[data-category]").forEach(btn => {
          btn.addEventListener("click", () => {
            const key = btn.getAttribute("data-category");
            if (key === "quick") state.searchQuery = "quick";
            if (key === "protein") state.searchQuery = "high protein";
            if (key === "plant") state.searchQuery = "vegan";
            state.searchCuisine = "All";
            setTab("search");
            toast("Filter applied");
          });
        });
      }
    }

    if (state.activeTab === "search") {
      const input = $("#searchInput");
      const cuisineSelect = $("#cuisineSelect");
      const btnReset = $("#btnReset");

      input?.addEventListener("input", (e) => {
        state.searchQuery = e.target.value || "";
        renderSearchResults();
      });
      cuisineSelect?.addEventListener("change", (e) => {
        state.searchCuisine = e.target.value;
        renderSearchResults();
      });
      btnReset?.addEventListener("click", () => {
        state.searchQuery = "";
        state.searchCuisine = "All";
        render();
        toast("Cleared");
      });

      renderSearchResults();
    }

    if (state.activeTab === "details") {
      $("#btnBackToBrowse")?.addEventListener("click", () => setTab("browse"));
      $("#btnDetailsBrowse")?.addEventListener("click", () => setTab("browse"));
      $("#btnDetailsSearch")?.addEventListener("click", () => setTab("search"));
      $("#btnCopyLink")?.addEventListener("click", async () => {
        const id = state.selectedRecipeId;
        if (!id) return;
        const url = new URL(window.location.href);
        url.hash = `recipe=${encodeURIComponent(id)}`;
        try {
          await navigator.clipboard.writeText(url.toString());
          toast("Link copied");
        } catch {
          toast("Copy not available");
        }
      });
    }
  };

  const renderSearchResults = () => {
    const grid = $("#searchGrid");
    const count = $("#searchCount");
    if (!grid || !count) return;

    const q = state.searchQuery.trim().toLowerCase();
    const cuisine = state.searchCuisine;

    const matches = recipes.filter(r => {
      if (cuisine !== "All" && r.cuisine !== cuisine) return false;

      if (!q) return true;

      const hay = [
        r.title, r.cuisine, r.difficulty, r.description,
        ...(r.tags || []),
        ...(r.ingredients || [])
      ].join(" ").toLowerCase();

      // allow a few "smart" keywords
      if (q === "quick") return r.minutes <= 25;
      if (q === "vegan") return (r.tags || []).includes("Vegan");
      if (q === "high protein") return (r.tags || []).includes("High Protein");

      return hay.includes(q);
    });

    count.textContent = `${matches.length} result${matches.length === 1 ? "" : "s"}`;
    grid.innerHTML = matches.map(recipeCardHTML).join("");

    grid.querySelectorAll("[data-recipe-id]").forEach(btn => {
      btn.addEventListener("click", () => selectRecipe(btn.getAttribute("data-recipe-id")));
    });
  };

  const recipeCardHTML = (r) => {
    return `
      <button class="recipeCard" type="button" data-recipe-id="${escapeHtml(r.id)}" aria-label="Open recipe ${escapeHtml(r.title)}">
        <div class="recipeCard__top">
          <div>
            <p class="recipeCard__title">${escapeHtml(r.title)}</p>
            <p class="recipeCard__meta">${escapeHtml(r.cuisine)} • ${r.minutes} min • ${escapeHtml(r.difficulty)}</p>
          </div>
          <span class="badge">${r.calories} cal</span>
        </div>
        <div class="pills" aria-label="Recipe tags">
          ${(r.tags || []).slice(0, 3).map(t => `<span class="pill">${escapeHtml(t)}</span>`).join("")}
        </div>
      </button>
    `;
  };

  const escapeHtml = (s) => String(s)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");

  // Deep link support: #recipe=r1
  const applyHash = () => {
    const hash = (window.location.hash || "").replace(/^#/, "");
    if (!hash) return;
    const m = hash.match(/^recipe=(.+)$/);
    if (!m) return;
    const id = decodeURIComponent(m[1]);
    if (recipeById(id)) {
      state.selectedRecipeId = id;
      setTab("details");
    }
  };

  // Initial mount
  render();
  applyHash();
})();
"""
