# Deploy Vaani Seva (Flutter Web) on Vercel — branch-only (`abhishek/dashboard`)

This folder is the **frontend only**. The backend URL is set at **build time** via `API_BASE_URL` (see [lib/services/api_service.dart](lib/services/api_service.dart)). You do **not** put `GEMINI_API_KEY` on Vercel; the backend holds that key.

---

## 1) Grant Vercel access to the shared GitHub repo

If Vercel only lists your **personal** repos, the **Vercel GitHub App** has not been granted access to `amanshekhar0/hack2skill` yet.

### Option A — You grant access (if GitHub allows)

1. GitHub → your avatar → **Settings** → **Applications** → **Installed GitHub Apps** → **Vercel** → **Configure**.
2. **Repository access** → **Only select repositories** → add **`amanshekhar0/hack2skill`** → Save.

### Option B — Repo owner grants access (if Option A is blocked)

Ask **Aman** (owner of `amanshekhar0/hack2skill`) to install/configure the **Vercel** GitHub App and grant access to **`hack2skill`**.

### Option C — No GitHub integration

From this directory, with [Vercel CLI](https://vercel.com/docs/cli): `npx vercel` then `npx vercel --prod`. You redeploy manually when you change code.

---

## 2) Create the Vercel project (frontend root)

1. Vercel → **Add New…** → **Project** → Import **`amanshekhar0/hack2skill`**.
2. **Root Directory**: set to **`vaani_seva`** (required).
3. Framework: **Other** is fine; build is defined by [vercel.json](vercel.json).

Build is: `bash vercel-build.sh` → output **`build/web`**.

---

## 3) Production branch + branch-only auto-deploys

1. Vercel → **Project** → **Settings** → **Git** → **Production Branch** → **`abhishek/dashboard`**.
2. This repo’s [vercel.json](vercel.json) also restricts Git-triggered deployments to **`abhishek/dashboard`** only (`git.deploymentEnabled` + [vercel-ignore-branch.sh](vercel-ignore-branch.sh) via `ignoreCommand`).  
   **Important:** `vercel.json` must exist on the branch that pushes (it does on `abhishek/dashboard`).

---

## 4) Environment variable (backend URL)

Vercel → **Settings** → **Environment Variables**:

| Name            | Value                         | Environments        |
|-----------------|-------------------------------|---------------------|
| `API_BASE_URL`  | Sadhu’s backend base URL only | Production (+ Preview if you want previews) |

- Use **no trailing slash**, e.g. `https://api.example.com`.
- Redeploy after changing this variable.

Local build equivalent:

```bash
flutter build web --release --dart-define=API_BASE_URL=https://your-backend.example.com
```

---

## 5) Deploy and verify

1. Click **Deploy** (or push to `abhishek/dashboard`).
2. First build can take **several minutes** (Flutter SDK is installed on the build machine).
3. In the browser, check:
   - Splash → language (English / Hindi / Kannada).
   - Form → submit → results (calls backend **`/predict`**).
   - Guide / voice flows if you use them (**`/generate_guide`**, **`/parse_voice`**).
4. If the browser console shows **CORS** errors, ask Sadhu to allow your Vercel origin on the Flask app (e.g. `https://<project>.vercel.app`).

---

## Troubleshooting

| Issue | What to do |
|--------|------------|
| Repo not in Vercel import list | Complete **§1** (GitHub App access). |
| Build fails on `bash` | Vercel Linux builders include `bash`; keep **Root Directory** = `vaani_seva`. |
| App loads but API fails | Set **`API_BASE_URL`**, redeploy; check backend **`/health`** and CORS. |
