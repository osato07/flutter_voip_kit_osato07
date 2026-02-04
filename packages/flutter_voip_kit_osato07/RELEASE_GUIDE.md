# Flutter VoIP Kit 公開・導入ガイド

このライブラリをGitHubで公開し、他のアプリから利用する方法（Pub.devを使わない方法）を解説します。

---

## 1. GitHubへのアップロード

### パターンA：このプロジェクト全体（Monorepo）として公開する場合
現在のフォルダ構成のままGitHubにアップロードします。一番手軽な方法です。
`packages/flutter_voip_kit_osato07` フォルダがリポジトリの中階層にある状態です。

### パターンB：ライブラリ単体として切り出す場合（推奨）
よりきれいに管理したい場合、新しいリポジトリを作成し、`packages/flutter_voip_kit_osato07` の中身だけを移動させます。

**必要なファイル構成（ルート直下）:**
```text
flutter_voip_kit_osato07/
  ├── android/
  ├── ios/
  ├── lib/
  ├── pubspec.yaml
  ├── README.md
  ├── LICENSE
  └── CHANGELOG.md
```

---

## 2. 他のアプリでのインストール方法

利用したいアプリの `pubspec.yaml` に、以下のように記述してGitHubから直接インストールします。

### パターンA（フォルダ全体）の場合
`path` オプションを使って、リポジトリ内のどこにパッケージがあるかを指定します。

```yaml
dependencies:
  flutter_voip_kit_osato07:
    git:
      url: https://github.com/あなたのユーザー名/リポジトリ名.git
      path: packages/flutter_voip_kit_osato07  # パッケージがあるフォルダパス
      ref: main                        # ブランチ名（またはタグ v1.0.0など）
```

### パターンB（ライブラリ単体）の場合
リポジトリのルートがそのままパッケージなので、URLだけでOKです。

```yaml
dependencies:
  flutter_voip_kit_osato07:
    git:
      url: https://github.com/あなたのユーザー名/flutter_voip_kit_osato07.git
      ref: main
```

---

## 3. 専用ドキュメントページを作る（GitHub Pages）

Dart標準のドキュメント生成ツール (`dart doc`) を使って、API仕様書をWebページとして公開できます。

### 手順
1.  **ドキュメント生成**:
    ターミナルで `packages/flutter_voip_kit_osato07` フォルダに移動し、以下を実行します。
    ```bash
    dart doc .
    ```
    `doc/api` フォルダが自動生成されます。これにHTMLファイル一式が入っています。

2.  **GitHub Pagesの設定**:
    生成された `doc/api` の中身を、GitHub Pagesで公開するフォルダ（例: `docs`）に移動してPushするか、GitHub Actions設定を行います。

    **一番簡単な方法（docsフォルダ使用）:**
    1. リポジトリのルートに `docs` フォルダを作成。
    2. `doc/api` の中身をすべて `docs` にコピー。
    3. GitHubにPush。
    4. リポジトリの **Settings** > **Pages** を開く。
    5. **Source** を `Deploy from a branch` に設定。
    6. Branchを `main`、フォルダを `/docs` にして Save。

    数分後、`https://ユーザー名.github.io/リポジトリ名/` にアクセスすると、きれいなAPIドキュメントが表示されます。

---

## 4. バージョン管理のヒント

開発が進んで変更を加えた場合、使う側のアプリが壊れないように「タグ」を打つことをお勧めします。

**リポジトリ側:**
```bash
git tag v0.0.1
git push origin v0.0.1
```

**使う側 (pubspec.yaml):**
```yaml
    git:
      url: ...
      ref: v0.0.1  # mainではなくタグを指定するとバージョンが固定されます
```
