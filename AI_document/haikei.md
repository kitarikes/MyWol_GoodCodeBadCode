# 開発背景と本日の議論フローまとめ

## プロジェクトの開発背景

- **目的**：Markdownベースで記事を書き、技術ブログや思いつきを「カテゴリごと」に分けて投稿・表示できるブログアプリを、  
  「変更容易性（Maintainability / Extensibility）」を高める設計手法を実践しながら構築する。  
- **初期要件**
  1. Markdownファイルを手動アップロードして記事を公開
  2. カテゴリ設定・スタイル定義を容易に変更できる
  3. CSSの記述方法も将来的な変更を考慮
  4. 後続フェーズではWeb上でMarkdown編集・画像アップロード機能を追加
  5. パフォーマンスチューニングを見据えた構成

---

## 今日の議論フロー

1.  **技術スタックの選定**
2.  **Markdown → クラス付与 → Tailwind CSS生成**
3.  **投稿ストレージとSSG設定**
4.  **初期フェーズ → 将来移行を見据えたカテゴリ管理**
5.  **ディレクトリ構成案のブラッシュアップ**
6.  **レイヤード vs. Feature-based構成の検討**
7.  **共通ロジックの集約方法**
8.  **CI/CD／ワークスペース設計の検討**
9.  **残タスクの確認**

---

## 1. 技術スタックの選定

### 背景

-   React＋TypeScriptで書きやすく、静的生成（SSG）・再生成（ISR）を柔軟に切り替えたい
-   MDXでMarkdown内にReactコンポーネント埋め込みを実現

### 決定

-   **Next.js (+ TypeScript)** を採用
-   MDX対応プラグイン（`@next/mdx`, `remark`/`rehype`）を導入

### 理由

-   Vercel連携で自動ビルド＆配信が容易
-   MDX＋Reactコンポーネントで拡張性高く記事を記述可能

---

## 2. Markdown → Tailwind CSS生成パイプライン

### 背景

-   記事スタイルを後から一括変更できる仕組みが必要
-   CSSの冗長化を防ぎ、ユーティリティファーストでメンテ性を向上

### 決定

-   **Tailwind CSS** ＋ `@tailwindcss/typography`
-   `tailwind.config.js` の `content` に `.mdx`/`.tsx` を指定
-   remark/rehypeプラグインで自動ID付与やカスタムディレクティブ対応

### 理由

-   デザイントークンは設定ファイル集中管理 → 一括変更
-   利用クラスだけを抽出した最適化CSS生成

---

## 3. 投稿ストレージ＆SSG設定

### 背景

-   初期はファイルベースでスピード重視、将来動的CMSに移行予定
-   Vercel上でSQLiteを読み取り専用で利用

### 決定

-   **SQLite（`prisma/dev.db`）** をGit管理
-   Next.jsの `getStaticPaths` + `fallback: 'blocking'` + `revalidate: 60`
-   環境変数：
    -   `NEXT_PUBLIC_USE_DB=false`（初期はファイルベース実装）
    -   `INITIAL_BUILD_COUNT=100`（初期ビルド件数）

### 理由

-   SSG+ISRでパフォーマンス担保しつつ、書き込みは後続フェーズでマネージドDBへ移行
-   SQLite→PostgreSQL→Headless CMSへの移行パスを保持

---

## 4. カテゴリ管理戦略

### 背景

-   カテゴリ変更頻度は低いが、将来的に管理UIで動的追加も必要
-   A（ビルド時定義）→B（ランタイム管理）切替を容易に

### 決定

-   初期は **`data/categories.json`** でビルド時定義
-   Repositoryパターン + DIフラグ（`USE_DB`）で切替
-   将来：Prisma+管理UIで動的CRUD & ISR

### 理由

-   フラグ一つでFile↔DB実装を差し替え可能
-   ビルド時定義のシンプル運用と拡張性の両立

---

## 5. ディレクトリ構成（Feature-based）

```text
my-blog/
├─ config/                  # env / Next.js / Tailwind 設定
├─ prisma/                  # schema & migrations & dev.db
├─ db/                      # seed.ts / migrate.ts
├─ src/
│   ├─ core/                # errors, logging, http, mdxExtensions
│   ├─ features/
│   │   ├─ posts/           # domain / repository / usecases / pipeline / components
│   │   └─ categories/      # domain / repository / usecases / components
│   ├─ components/          # グローバルUI（Header, Footer, GlobalLayout）
│   └─ pages/               # Next.js 自動ルーティング
└─ .github/workflows/ci.yml # ワークスペース＋マトリックス＋キャッシュ
```

#### 理由

-   機能単位でロジックが隣接 → 保守性・可読性向上
-   `core` に横断的関心事を一元化

---

## 6. 共通ロジックの集約（src/core）

-   `errors`：ApiError など
-   `logging`：`logger.ts`（pino/winston wrapper）
-   `http`：APIリクエスト/レスポンスユーティリティ
-   `mdx`：MDX→HTML変換パイプライン共通設定

→ TypeScriptパスエイリアス で `@core/...` から容易に利用

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

---

## 7. CI/CD設計

-   pnpm/Yarn Workspaces をベースに各featureを仮想パッケージ化
-   GitHub Actions Matrix で `src/features/{posts,categories}` ごとにLint/Testを並列実行
-   `actions/cache` で `~/.pnpm-store` / `.next/cache` をキャッシュ
-   buildジョブはテスト通過後に全体ビルド

---

## 8. 設定ファイルの一元化

-   ESLint / Prettier / Jest / tsconfig / Next.js / Tailwind 設定はすべてルート直下
-   feature配下でのオーバーライド設定は極力不要


# 次にすべきタスク

1. **Prisma スキーマ＆マイグレーション準備**  
   - `schema.prisma` のモデル定義を確定  
   - `prisma migrate dev` で `dev.db` を更新・コミット  
   - `db/migrate.ts` を CI でも動く形式に整備

2. **core モジュールの実装**  
   - `src/core/errors/ApiError.ts` に共通例外クラス追加  
   - `src/core/logging/logger.ts` でロガーラッパー整備  
   - `src/core/http/httpUtil.ts` にリクエスト／レスポンスユーティリティ実装  
   - `src/core/mdx/mdxExtensions.ts` を feature パイプラインから参照できるように

3. **posts 機能の骨組み作成**  
   - ドメイン：`src/features/posts/domain` に `Post.ts`, `PostCollection.ts`  
   - リポジトリ：`IPostRepository`＋ `FilePostRepo`/`DbPostRepo` の雛形  
   - ユースケース：`GetPostUseCase.ts` の実装  
   - パイプライン：MDX→Tailwind 読み込み処理の組み込み  
   - コンポーネント：`MDXLayout.tsx`, `PostCard.tsx`

4. **categories 機能の骨組み作成**  
   - ドメイン：`Category.ts`, `CategoryCollection.ts`  
   - リポジトリ：`ICategoryRepo`＋ `FileCategoryRepo`/`DbCategoryRepo`  
   - ユースケース：`ListCategoriesUseCase.ts`  
   - コンポーネント：`CategoryList.tsx`

5. **グローバルレイアウト＆ページルーティング**  
   - `src/components/layout/GlobalLayout.tsx` にヘッダー・フッター組み込み  
   - `src/pages/index.tsx`, `posts/[slug].tsx`, `categories/[slug].tsx` の雛形

6. **TypeScript パスエイリアス設定**  
   - `tsconfig.json` に `@core/*` と `@features/*` を追加  
   - 各モジュールからエイリアスでインポートできるか動作確認

7. **CI/CD ワークフローの最終調整**  
   - `.github/workflows/ci.yml` の matrix テストを動かして合格させる  
   - キャッシュ設定（`~/.pnpm-store`, `.next/cache`）の検証  
   - Lint／Test／Build が通ることを確認

8. **シードスクリプトとマイグレーションスクリプトの運用化**  
   - `db/seed.ts` を CI で実行し、初期データを自動投入  
   - `db/migrate.ts` をステージング／本番でも動くようチェック

9. **基本的なユニット＆統合テスト作成**  
   - `tests/features/posts` / `tests/features/categories` にユースケースのテスト  
   - `tests/components` にレイアウト・MDX レンダリングのスナップショットテスト

10. **次フェーズ検討：Webエディタ＆画像アップロード**  
    - エディタ選定（TipTap など）と画像ストレージ（S3／Cloudinary）の検討  
    - 管理UIの認証フロー設計