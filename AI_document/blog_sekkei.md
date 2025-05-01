# 本日決定事項

## 1. フロントエンド＆Markdown パイプライン
- フレームワーク：**Next.js (+ TypeScript)**
- 記事フォーマット：**MDX**
- Tailwind CSS を採用し、`@tailwindcss/typography` プラグイン＋remark/rehype プラグインで
  - Markdown → JSX → Tailwind ユーティリティクラス付与 → 最適化された CSS 生成

## 2. 投稿ストレージ／SSG 設定
- **SQLite**（`prisma/dev.db`）を Git 管理
- Next.js の `getStaticProps` / `getStaticPaths` でビルド時に静的生成
  - `fallback: 'blocking'` ＋ `revalidate: 60`（ISR）
  - 環境変数
    - `NEXT_PUBLIC_USE_DB=false`（初期：ファイルベース）
    - `INITIAL_BUILD_COUNT=100`（初期ビルド件数）

## 3. ディレクトリ構成（抜粋）

```text
my-blog/
├─ .env
├─ next.config.js
├─ tailwind.config.js
├─ tsconfig.json
├─ package.json
├─ prisma/
│   ├─ migrations/
│   ├─ schema.prisma
│   └─ dev.db
├─ db/
│   ├─ seed.ts
│   └─ migrate.ts
├─ src/
│   ├─ core/
│   │   ├─ errors/         # ApiError など
│   │   ├─ logging/        # logger wrapper
│   │   ├─ http/           # APIユーティリティ
│   │   └─ mdx/            # MDX pipeline 共通設定
│   ├─ features/
│   │   ├─ posts/          # domain/repository/usecases/pipeline/components
│   │   └─ categories/     # domain/repository/usecases/components
│   ├─ components/
│   │   └─ layout/         # Header, Footer, GlobalLayout
│   └─ pages/              # Next.js 自動ルーティング
│       ├─ api/revalidate.ts
│       ├─ posts/[slug].tsx
│       ├─ categories/[slug].tsx
│       └─ index.tsx
├─ .github/
│   └─ workflows/ci.yml    # ワークスペース＋マトリックス＋キャッシュ
```

## 4. 共通ロジック集約
- `src/core/` に横断的関心事を集約
- エラー処理 (`errors/`)
- ロギング (`logging/`)
- HTTP ユーティリティ (`http/`)
- MDX 拡張 (`mdx/`)
- パスエイリアス（`tsconfig.json`）

```json
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@core/*": ["src/core/*"],
      "@features/*": ["src/features/*"]
    }
  }
}
```

## 5. CI/CD 設計
- pnpm/Yarn Workspaces と GitHub Actions Matrix による機能単位テスト
- キャッシュ（`~/.pnpm-store`, `.next/cache`）で依存解決／ビルドを高速化
- Lint／テストは `src/features/{posts,categories}` ごとに並列実行

## 6. 設定ファイルの一元化
- ESLint、Prettier、Jest、tsconfig、Next.js、Tailwind の設定をすべてルートに配置
- feature 配下でのローカルオーバーライドは最小限に
