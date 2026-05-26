# PR Preview Setup Guide

This guide explains how to set up automatic preview deployments for pull requests, so you can test the web app before merging.

## Option 1: Netlify (Recommended - Free for Public Repos)

### Features
- ✅ Automatic preview deployments for every PR
- ✅ Unique URL for each PR (e.g., `deploy-preview-224--essentiel.netlify.app`)
- ✅ Free for public repositories
- ✅ Automatic SSL certificates
- ✅ Built-in build logs and deploy status
- ✅ Comments on PR with preview URL

### Setup Steps

1. **Sign up for Netlify** (if you haven't already)
   - Go to [netlify.com](https://www.netlify.com/)
   - Sign in with GitHub

2. **Import your repository**
   - Click "Add new site" → "Import an existing project"
   - Choose GitHub and authorize Netlify
   - Select `lemra-org/essentiel_app`

3. **Configure build settings**
   - **Build command**: (automatically detected from `netlify.toml`)
   - **Publish directory**: `build/web`
   - Click "Deploy site"

4. **Enable PR previews**
   - Go to Site Settings → Build & deploy → Deploy contexts
   - Enable "Deploy Preview" for pull requests
   - Enable "Branch deploys" if desired

5. **Add Flutter build image**
   - Go to Site Settings → Build & deploy → Build image selection
   - Select Ubuntu Focal 20.04 (default)
   - Add build environment variable:
     - Key: `FLUTTER_ROOT`
     - Value: `/opt/flutter`

6. **Install Flutter in build**
   - Netlify will use the build command from `netlify.toml`
   - Flutter will be downloaded and cached automatically

### Configuration

The repository includes `netlify.toml` with optimized settings:
- Production builds use `web_prod.dart` environment
- Preview builds use `web_dev.dart` environment
- Caching headers for optimal performance
- SPA routing redirects

### Result

Every PR will get:
- ✅ Automatic build on push
- ✅ Preview URL comment in PR
- ✅ Deploy status check
- ✅ Rollback capability

Example preview URL: `https://deploy-preview-224--essentiel-app.netlify.app`

---

## Option 2: Vercel

### Features
- ✅ Automatic preview deployments
- ✅ Unique URL per PR
- ✅ Free for hobby projects
- ✅ Fast global CDN
- ✅ Built-in analytics

### Setup Steps

1. **Sign up for Vercel**
   - Go to [vercel.com](https://vercel.com/)
   - Sign in with GitHub

2. **Import repository**
   - Click "Add New" → "Project"
   - Import `lemra-org/essentiel_app`

3. **Configure build**
   - Framework Preset: `Other`
   - Build Command:
     ```bash
     flutter config --enable-web && \
     flutter pub get && \
     flutter build web --release --base-href="/" --pwa-strategy offline-first -t lib/environments/web_prod.dart
     ```
   - Output Directory: `build/web`
   - Install Command: (leave empty)

4. **Add environment variables**
   - Go to Settings → Environment Variables
   - Add:
     - `FLUTTER_VERSION` = `3.22.3`
     - `FLUTTER_CHANNEL` = `stable`

5. **Deploy**
   - Click "Deploy"
   - Vercel will install Flutter and build your app

### Vercel Configuration (Optional)

Create `vercel.json` in repository root:

```json
{
  "buildCommand": "flutter config --enable-web && flutter pub get && flutter build web --release --base-href='/' --pwa-strategy offline-first -t lib/environments/web_prod.dart",
  "outputDirectory": "build/web",
  "framework": null,
  "rewrites": [
    {
      "source": "/(.*)",
      "destination": "/index.html"
    }
  ],
  "headers": [
    {
      "source": "/flutter_service_worker.js",
      "headers": [
        {
          "key": "Cache-Control",
          "value": "no-cache, no-store, must-revalidate"
        }
      ]
    },
    {
      "source": "/(.*).js",
      "headers": [
        {
          "key": "Cache-Control",
          "value": "public, max-age=31536000, immutable"
        }
      ]
    }
  ]
}
```

---

## Option 3: GitHub Actions Artifacts (Current Setup)

### Features
- ✅ Already configured in `.github/workflows/web-pr-preview.yml`
- ✅ No external service needed
- ✅ Free (uses GitHub Actions minutes)
- ❌ No live URL (must download and test locally)

### How it works

1. PR is created or updated
2. Workflow builds the web app
3. Build is uploaded as artifact
4. Comment is posted on PR with download instructions

### Testing a PR preview

1. Go to the PR
2. Click "Checks" tab
3. Find "Web PR Preview" workflow
4. Download "web-build-pr-XXX" artifact
5. Extract and serve locally:
   ```bash
   cd build/web
   python3 -m http.server 8000
   ```
6. Open http://localhost:8000

---

## Option 4: Cloudflare Pages

### Features
- ✅ Automatic preview deployments
- ✅ Unlimited bandwidth
- ✅ Global CDN
- ✅ Free tier generous

### Setup Steps

1. **Sign up for Cloudflare Pages**
   - Go to [pages.cloudflare.com](https://pages.cloudflare.com/)
   - Connect GitHub account

2. **Create project**
   - Click "Create a project"
   - Select `lemra-org/essentiel_app`

3. **Configure build**
   - Build command:
     ```bash
     flutter config --enable-web && \
     flutter pub get && \
     flutter build web --release --base-href="/" --pwa-strategy offline-first -t lib/environments/web_prod.dart
     ```
   - Build output directory: `build/web`

4. **Deploy**
   - Click "Save and Deploy"

5. **Enable PR previews**
   - Automatically enabled by default
   - Each PR gets a unique URL

---

## Comparison

| Feature | Netlify | Vercel | GitHub Actions | Cloudflare Pages |
|---------|---------|--------|----------------|------------------|
| **Automatic PR previews** | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| **Live preview URL** | ✅ Yes | ✅ Yes | ❌ No | ✅ Yes |
| **Free tier** | ✅ Generous | ✅ Good | ✅ Included | ✅ Unlimited |
| **Build time** | ~3-5 min | ~3-5 min | ~3-5 min | ~3-5 min |
| **Setup complexity** | ⭐ Easy | ⭐ Easy | ⭐⭐ Medium | ⭐ Easy |
| **Custom domain** | ✅ Yes | ✅ Yes | ❌ No | ✅ Yes |
| **SSL** | ✅ Auto | ✅ Auto | N/A | ✅ Auto |
| **Analytics** | ✅ Yes | ✅ Yes | ❌ No | ✅ Yes |

---

## Recommendation

**For this project**: Use **Netlify**

**Reasons:**
1. ✅ `netlify.toml` already configured in repository
2. ✅ Easy GitHub integration
3. ✅ Generous free tier for public repos
4. ✅ Automatic preview URLs for every PR
5. ✅ Built-in PR comments with preview links
6. ✅ No additional configuration needed

**Setup time**: ~5 minutes

---

## Testing Backend Integration

**Important**: Preview deployments will use the production backend URL (`https://api.essentiel.app`).

Ensure:
1. Backend API is deployed to production
2. CORS is configured to allow preview domains:
   - Netlify: `*.netlify.app`
   - Vercel: `*.vercel.app`
   - Cloudflare: `*.pages.dev`

Alternatively, update `lib/environments/web_dev.dart` to use a test backend for previews.

---

## Next Steps

1. Choose your preferred option (Netlify recommended)
2. Follow the setup steps above
3. Push a commit to your PR
4. Preview deployment will trigger automatically
5. Click the preview URL in the PR comment
6. Test the web app in your browser!

🎉 You'll now have automatic preview deployments for every PR!
