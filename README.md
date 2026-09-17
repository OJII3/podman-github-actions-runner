# Podman GitHub Actions runner

Ubuntu 24.04 ベースの GitHub Actions self-hosted runner を、Podman の
rootless socket 経由で動かすための最小構成です。

runner コンテナには Docker daemon を入れません。`docker` CLI を Podman の
Docker API compatibility endpoint に接続し、workflow から実行される
`docker run` を Podman に処理させます。

コンテナ内の runner は root として動きますが、ホスト側では rootless Podman の
実行ユーザーにマッピングされます。これは、コンテナ内から bind mount した
Podman socket を利用するためです。

## 前提

- Linux ホストに Podman 5 以降がインストール済み
- `podman compose` が使える compose provider（`podman-compose` など）
- rootless Podman socket が起動済み
- GitHub Actions runner を登録できる権限
- Unity build 用の十分なディスク容量とメモリ

runner を起動するユーザーで rootless socket を有効化します。

```sh
systemctl --user enable --now podman.socket
```

`podman compose` 自体は compose provider を必要とします。環境に応じて
`podman-compose` または Docker Compose v2 をインストールしてください。

通常の socket は次の場所です。

```text
/run/user/<UID>/podman/podman.sock
```

## セットアップ

### 1. runner を配置する

GitHub の `Settings > Actions > Runners > New self-hosted runner` から
Linux x64 runner をダウンロードし、`.env` の `RUNNER_ROOT` に設定した
ディレクトリへ展開します。

既に別の場所へ展開済みの場合は、その絶対パスを `.env` の
`RUNNER_ROOT` に設定すれば移動は不要です。この repository の例では、
現在の runner 配置先をそのまま使う設定にしています。

新しく配置する場合の例:

```sh
mkdir -p /srv/gha-runner
cd /srv/gha-runner
# GitHub が表示する download / tar コマンドをここで実行
```

`RUNNER_ROOT` は必ず絶対パスにしてください。GameCI が Unity コンテナへ
workspace や action files を bind mount するため、runner コンテナ内と
Podman ホストで同じパスが見える必要があります。

### 2. 設定ファイルを作る

リポジトリ直下で実行します。

```sh
cp .env.example .env
chmod 600 .env
```

`.env` の `RUNNER_URL`、`RUNNER_TOKEN`、`RUNNER_ROOT`、`PODMAN_SOCKET` を
環境に合わせて変更します。`.env` は commit しません。

### 3. 起動する

```sh
podman compose build
podman compose up -d
podman compose logs -f runner
```

runner が接続したら、workflow の `runs-on` に `podman` label を指定します。

```yaml
runs-on: [self-hosted, linux, x64, podman]
```

## 動作確認

まずは runner コンテナから Podman API に接続できるか確認します。

```sh
podman compose exec runner docker version
podman compose exec runner docker run --rm docker.io/library/alpine:3.20 true
```

その後、Unity image を pull します。image が大きいため、初回は時間がかかります。

```sh
podman compose exec runner \
  docker pull docker.io/unityci/editor:ubuntu-6000.3.7f1-android-3.2.2
```

## GameCI Unity Builder

次の設定はこの構成で想定しています。

```yaml
providerStrategy: local
customImage: docker.io/unityci/editor:ubuntu-6000.3.7f1-android-3.2.2
runAsHostUser: true
```

`runAsHostUser: true` は self-hosted runner で生成ファイルの所有者を合わせる
ため、そのまま使用してください。runner directory は、runner コンテナ内と
Podman ホストで同じ絶対パスが見えるように bind mount します。

この構成は GameCI が直接 `docker run` を呼ぶ workflow 向けです。GitHub Actions
の `container:`、`services:`、Docker-in-Docker、Docker Buildx を併用する場合は、
別途互換性確認が必要です。

## セキュリティ

Podman socket を使える workflow は、そのユーザー権限で Podman のコンテナを
操作できます。信頼できる private repository 専用 runner として使用し、
公開 repository の fork から実行される workflow には割り当てないでください。
