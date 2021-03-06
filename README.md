# automeasurement

AutoMeasurement(ATM) は VIS サスペンションのヘルスチェックの作業を簡素化するために、以下の機能を提供する。

 1. diaggui による伝達関数測定の自動化
 2. 他のサスペンションとの比較プロット
 3. 過去の測定結果との比較用プロット

## 目次

 * ファイル構成
   *  ファイル名の定義
     *  テンプレート名
     *  測定結果名
     *  プロット名
   * スクリプトファイル
     *  測定実行スクリプト
     *  プロット用スクリプト
 *  メモ, ToDo

## ファイル構成

AutoMeasurement の基本的なファイルは atmctl と atmplot のディレクトリに分けた。これらディレクトリで、diaggui 測定の自動化操作や、測定結果のプロットをおこなう。また補助的に、 ユーザーが medm 画面で GUI 操作できるようにするために portable channel access server (pcas) を立て、関連したEPICSチャンネルを生成している。pcas は pcas ディレクトリ内の docker で サーバーを動かし、medm 画面は medm ディレクトリにある。

上述したものも含め、その他ディレクトリやファイルは以下に示す。

 - README.md : 本ファイル
 - lib/atmctl : 自動測定用のパッケージ
 - lib/atmplot : 測定結果プロット用のパッケージ
 - pcas : EPICSチャンネル用のサーバー
 - medm : GUI 画面
 - templates: 自動測定用の管理用テンプレートファイル
 - settings : 環境変数用のファイル
 - bin : 各種実行ファイル
 - .gitignore : git 管理しないファイルを記述するファイル
 - LICENSE : ライセンスファイル

KAGRAの実行環境では、AutoMeasurement(ATM) は `ATM_DIR` に、測定結果は `ATM_SAVE_DIR` 以下に保存する。

```
ATM_DIR=/kagra/Dropbox/Subsystems/VIS/Scripts/automeasurement
ATM_SAVE_DIR=/kagra/Dropbox/Measurements/VIS/
```

### ファイル名の定義

AutoMeasurementは、テンプレートファイルをつかって測定をし、結果を別のファイルに保存する。そして測定結果を元にプロットを画像ファイルとして保存する。以下では3つの種類のファイル名を定義する。

#### テンプレートファイル

テンプレートはステージごとに用意する。例えば、`ETMX_IP_TEST_L` を励起したい場合は、

```${ATM_SAVE_DIR}/TEMPLATES/PLANT_ETMX_IP.xml```

 という測定用テンプレートファイルを使い、`TEST_L` の励起チャンネルを選んで励起する。ちなみにこの測定用テンプレートファイルは、git管理するテンプレートファイルを減らすために、簡素化した管理用テンプレートファイルから生成される。管理用テンプレートは各Typeごとに用意した。以下のように現在合計9ファイル存在する。

 * `${ATM_DIR}/templates/PLANT_TYPEA_IP.xml`
 * `${ATM_DIR}/templates/PLANT_TYPEA_BF.xml`
 * `${ATM_DIR}/templates/PLANT_TYPEA_GAS.xml`
 * `${ATM_DIR}/templates/PLANT_TYPEA_IM.xml`
 * `${ATM_DIR}/templates/PLANT_TYPEB_IP.xml`
 * `${ATM_DIR}/templates/PLANT_TYPEB_GAS.xml` 
 * `${ATM_DIR}/templates/PLANT_TYPEB_IM.xml`
 * `${ATM_DIR}/templates/PLANT_TYPEBP_BF.xml`
 * `${ATM_DIR}/templates/PLANT_TYPEBP_GAS.xml` 
 * `${ATM_DIR}/templates/PLANT_TYPEBP_IM.xml`

なお、テンプレートファイルを編集する際は、測定用ファイルは直接編集せずに、管理用ファイルを編集してから、`${ATM_DIR}/bin/init_templates.sh` を実行して測定用ファイルに変更を反映させること。また実際にテンプレートファイルを編集する場合、templates ディレクトリの README.md に注意されたい。

#### 測定結果ファイル

測定結果は Guardian の State 名と実行したタイムスタンプをファイル名に付与して保存する。例えば、`2022/02/18 19:06` に `STANDBY` ステートの `ETMX` の `ETMX_IP_TEST_L` を励起した測定結果のファイル名は、

```${ATM_SAVE_DIR}/PLANT/ETMX/2022/02/PLANT_ETMX_STANDBY_IP_TEST_L_202202181906.xml```

として保存する。なお、タイムスタンプは後述する **`run_plants.sh` が実行された時刻**であり、個々の測定テンプレートが実行された時刻ではないことに注意されたい。

#### プロットファイル

### 各種スクリプト
#### 測定実行スクリプト

測定は `run_plants.sh` と `run_plant.sh` をつかう。`run_plants.sh` は、ユーザーによって与えられたサスペンションとステージに基づいてテンプレートファイルを選び、保存ファイル名に GuardState とタイムスタンプを押す。`run_plant.sh` は`run_plant.sh` で与えられたテンプレートファイルを diag コマンドで実行し、与えられたファイル名で保存する。

`ETMX`の`IP`ステージの全自由度`L,T,Y`を測定したい場合を例に説明する。この場合まず、ユーザーは`run_plants.sh`に以下の引数を与えて実行する。

```
run_plants.sh ETMX IP TEST ALL
```

この実行が`2022/02/18 19:06` に `ETMX`が`STANDBY` ステートの状態であったのなら、以下のように、自由度`L,T,Y`についての 3つの`run_plant.sh` コマンドが作られる。

ちなみに`run_plant.sh` コマンドの引数は5つ必要である。最初の2つはテンプレートファイル名と保存ファイル名で、3つ目は励起チャンネル名、残りの2つはデバッグに関連したフラグを意味する。

```
run_plant.sh  \
${ATM_SAVE_DIR}/TEMPLATES/PLANT_ETMX_IP.xml \
${ATM_SAVE_DIR}/PLANT/ETMX/2022/02/PLANT_ETMX_STANDBY_IP_TEST_L_202202181906.xml \
K1:VIS-ETMX_IP_TEST_L_EXC \
$DEBUG \
$QUICK \ 

run_plant.sh  \
${ATM_SAVE_DIR}/TEMPLATES/PLANT_ETMX_IP.xml \
${ATM_SAVE_DIR}/PLANT/ETMX/2022/02/PLANT_ETMX_STANDBY_IP_TEST_T_202202181906.xml \
K1:VIS-ETMX_IP_TEST_T_EXC \
$DEBUG \
$QUICK \ 

run_plant.sh  \
${ATM_SAVE_DIR}/TEMPLATES/PLANT_ETMX_IP.xml \
${ATM_SAVE_DIR}/PLANT/ETMX/2022/02/PLANT_ETMX_STANDBY_IP_TEST_Y_202202181906.xml \
K1:VIS-ETMX_IP_TEST_Y_EXC \
$DEBUG \
$QUICK \ 
```
これら3つの`run_plant.sh` コマンドは`run_plants.sh`のforループで逐次実行される。

もし IP 以外の BF と GAS を含む Tower の全ステージで `run_plants.sh` を実行したい場合、引数`IP`の代わりに`TWR`を与えれば良い。なおステージも自由度も引数は1つしか与えられないことに注意されたい。つまり、IPとGASだけの測定はできない。

また複数のサスペンションの測定を同じタイムスタンプで保存したい場合、`run_plants.sh`を1分単位で同じ時刻で実行すればよい。今後`run_plants.sh`を並列で実行するスクリプトを用意する予定であるが、それまで面倒だがこの方法で行うことになる。


### トラブルシュート

テンプレを更新したのに反映されない
 * 管理用テンプレを更新したあと init_template.sh を実行したか確認
 * init_template.sh は測定用テンプレを更新しているか確認

MEDMが白抜きになった
 * pcas の再起動をする。（pcas/99_restart.sh を実行してDockerにログイン後、python3 run.py を実行）
 * もしpcas自体のエラーで再び白抜きになる場合、適宜 run.py を修正したのち再起動すること。もし解決しない場合は maintainer に連絡。

Docker を常に起動させておきたい
 * デバッグを頻繁におこなうために、常時起動しないように設定ファイルの該当部分をコメントアウトしているので、それを外せば良い。
 * pcas/build/pcas/Dockerfile の ENTRYPOINT をコメントアウトをはずしてpcasの再起動をする。これで起動時に run.py を走らせるようになる。

Docker をやめたい
 * 管理の問題などから、Dockerをやめたい場合は基本的には、環境設定済みの計算機のうえで `lib/run.py` を実行するだけ。
 * ただし Docker で EPICS チャンネルを KAGRA のものと隔離していたので、EPICS_CA_ADDRLIST という環境変数の書き換えをしていた都合上、この環境変数を適宜移行した計算機の環境に合わせる必要がある。また AUTOMEASUREMENT.adl 自体は 172.20.0.2 という Docker の EPICS Gateway を見るようにしているので、それを移行環境に対応する必要があることに注意。

k1ctr27 から k1script へ移行したい
 * 基本的にDockerがインストールされれば、k1ctr27でしていることと同じことをすればよい。つまり、pcas/99_restart.sh を実行してpcasを起動すればOK。


### メモ, ToDo

 * 管理用テンプレファイルファイルを減らせないか

### ブランチ
 * main: 最新ブランチ(安定)
 * develop: main に機能修正などが加わったブランチ(不安定)
 * plant: 伝達関数測定ができる
 * spectra: スペクトル測定ができる