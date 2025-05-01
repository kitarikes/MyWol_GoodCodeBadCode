# 良いコード悪いコードで学ぶ設計

ソフトウェアの設計は「変更や拡張をどれだけ楽にできるか」が大事です。本資料では、**コードの保守性・拡張性を高めるための設計指針**を、具体例を交えながら整理しています。

## 目次

1. [関心の分離（分割統治）](#1-関心の分離分割統治)
   1.1 [メソッド分割の基本](#11-メソッド分割の基本)
   1.2 [カプセル化とデータ保護](#12-カプセル化とデータ保護)
   1.3 [プリミティブ引数の型安全化](#13-プリミティブ引数の型安全化)

2. [設計パターンの基本](#2-設計パターンの基本)
   2.1 [完全コンストラクタ](#21-完全コンストラクタ)
   2.2 [値オブジェクト](#22-値オブジェクト)
   2.3 [ストラテジ / ポリシー](#23-ストラテジ--ポリシー)
   2.4 [ファーストクラスコレクション](#24-ファーストクラスコレクション)
   2.5 [スプラウトクラス](#25-スプラウトクラス)

3. [不変（Immutable）と再代入の防止](#3-不変immutableと再代入の防止)

4. [カプセル化による堅牢性向上](#4-カプセル化による堅牢性向上)

5. [関心の分離実践: 単一責任とDRY](#5-関心の分離実践-単一責任とdry)

6. [条件分岐の整理](#6-条件分岐の整理)

7. [インターフェース設計](#7-インターフェース設計)

8. [コレクションの扱い](#8-コレクションの扱い)

9. [健全性維持のための一般原則](#9-健全性維持のための一般原則)

10. [名前設計](#10-名前設計)

11. [コメント・ドキュメンテーション](#11-コメントドキュメンテーション)

12. [メソッド（関数）の詳細設計](#12-メソッド関数の詳細設計)

13. [リファクタリング](#13-リファクタリング)

---

## 1. 関心の分離（分割統治）

### 1.1 メソッド分割の基本

#### **ポイント**
- **1メソッド1目的**：一つの処理に複数の目的を詰め込まない
- メソッドが長いほど可読性が下がり、テストしづらくなります

#### **例：RPGゲームのダメージ計算**
```java
// --- 分割前 ---
int calcDamage(int playerArmPower, int playerWeaponPower,
               int enemyBodyDefence, int enemyArmorDefence) {
    int totalPlayerAttackPower = playerArmPower + playerWeaponPower;
    int totalEnemyDefence = enemyBodyDefence + enemyArmorDefence;
    int damageAmount = totalPlayerAttackPower - (totalEnemyDefence / 2);
    if (damageAmount < 0) {
        return 0;
    }
    return damageAmount;
}
```
- まとめて書かれているため、攻撃力計算、防御力計算、最終ダメージの計算が混ざって読みにくい

```java
// --- 分割後 ---
int sumUpPlayerAttackPower(int playerArmPower, int playerWeaponPower) {
    return playerArmPower + playerWeaponPower;
}

int sumUpEnemyDefence(int enemyBodyDefence, int enemyArmorDefence) {
    return enemyBodyDefence + enemyArmorDefence;
}

int estimateDamage(int totalPlayerAttackPower, int totalEnemyDefence) {
    int damageAmount = totalPlayerAttackPower - (totalEnemyDefence / 2);
    return Math.max(damageAmount, 0);
}

// 呼び出し例
int totalPlayerAttack = sumUpPlayerAttackPower(playerArmPower, playerWeaponPower);
int totalEnemyDef = sumUpEnemyDefence(enemyBodyDefence, enemyArmorDefence);
int damage = estimateDamage(totalPlayerAttack, totalEnemyDef);
```
- それぞれの意図が明確になり、テストも簡単

よくある疑問

「メソッドが細かく分かれすぎてIDE上の参照が増えると、逆に見にくいのでは？」

- 適度な粒度が大切です。各メソッドが**「何をしているか」**明確になるなら分割は有効です。
- 1メソッドが長大化し「あちこち飛ぶより一箇所にまとめたい」というケースは、まず1メソッドが本当に単一の目的か 再確認しましょう。

---

### 1.2 カプセル化とデータ保護
- 「データと操作ロジック」はセットで1クラスにまとめる
- 外部にデータをさらさない → 不正値混入の防止

例：HitPoint（HP）のカプセル化

```java
class HitPoint {
    private static final int MIN = 0;
    private static final int MAX = 999;
    final int value;  // 不変

    HitPoint(final int value) {
        if (value < MIN) {
            throw new IllegalArgumentException("HPは" + MIN + "以上");
        }
        if (value > MAX) {
            throw new IllegalArgumentException("HPは" + MAX + "以下");
        }
        this.value = value;
    }

    // ダメージを受ける
    HitPoint damage(int damageAmount) {
        if (damageAmount < 0) {
            throw new IllegalArgumentException("ダメージ量が負");
        }
        int nextValue = Math.max(MIN, value - damageAmount);
        return new HitPoint(nextValue);
    }

    // 回復する
    HitPoint recover(int recoveryAmount) {
        if (recoveryAmount < 0) {
            throw new IllegalArgumentException("回復量が負");
        }
        int nextValue = Math.min(MAX, value + recoveryAmount);
        return new HitPoint(nextValue);
    }
}
```
- HPが負になることや上限を超えることをクラス自身が防ぎます
- ほかのクラスはHitPointの中身を直接操作できないので安全

---

### 1.3 プリミティブ引数の型安全化

問題点
- intやStringを使ってデータをやり取りすると、同じ型なのに意味が違うものが混在しやすい

例：金額 (Money)

```java
// --- 悪い例 ---
int pay(int price, int discount, int taxRate, String currencyCode) {
    // ...
    return price - discount; // いろいろ適用忘れが起きやすい
}
```

```java
// --- 型を作る例 ---
class Money {
    final int amount;
    final Currency currency;

    Money(int amount, Currency currency) {
        if (amount < 0) {
            throw new IllegalArgumentException("マイナス金額はNG");
        }
        this.amount = amount;
        this.currency = currency;
    }

    Money add(Money other) {
        if (!this.currency.equals(other.currency)) {
            throw new IllegalArgumentException("通貨違い");
        }
        return new Money(this.amount + other.amount, this.currency);
    }
}
```
- 「金額」はMoney型で扱うことで、加算・減算や通貨単位の不一致を型レベルで制御できる

---

## 2. 設計パターンの基本

### 2.1 完全コンストラクタ
- コンストラクタで必要なパラメータをすべて受け取り、その場でガード
- 生成後に不完全な状態にならないようにする

例

```java
class Product {
    private static final int MIN_PRICE = 0;
    final int price;
    final String name;

    Product(int price, String name) {
        if (price < MIN_PRICE) {
            throw new IllegalArgumentException("価格が負");
        }
        if (name == null || name.isBlank()) {
            throw new IllegalArgumentException("名前が空");
        }
        this.price = price;
        this.name = name;
    }
}
```
- この設計により、Productインスタンスは常にprice >= 0 && name != 空を保証

---

### 2.2 値オブジェクト
- 1つの「概念」を表すオブジェクトに、関連するロジックをすべて閉じ込める
- 金額、期日、重量、ポイント、在庫数など

例：ポイント割引

```java
class DiscountPoint {
    private final int point;

    DiscountPoint(int point) {
        if (point < 0) {
            throw new IllegalArgumentException("ポイントが負");
        }
        this.point = point;
    }

    DiscountPoint add(DiscountPoint other) {
        return new DiscountPoint(this.point + other.point);
    }

    // ほかにも、ポイント上限チェックなど必要に応じて集約
}
```
---

### 2.3 ストラテジ / ポリシー
- 条件分岐を削減し、実装切り替えを容易にする
- 例：ランクごとに異なる「ポイント付与率」、「送料計算方式」など

例：ランクごとのボーナスポイント
```java
interface RankBonus {
    int getBonus(int purchaseAmount);
}

class SilverRankBonus implements RankBonus {
    @Override
    public int getBonus(int purchaseAmount) {
        // シルバーは購入金額の1%
        return (int)(purchaseAmount * 0.01);
    }
}

class GoldRankBonus implements RankBonus {
    @Override
    public int getBonus(int purchaseAmount) {
        // ゴールドは1000P固定 + 2%
        return 1000 + (int)(purchaseAmount * 0.02);
    }
}

// 切り替え側（例：Mapで管理）
Map<RankType, RankBonus> rankBonuses = Map.of(
    RankType.SILVER, new SilverRankBonus(),
    RankType.GOLD, new GoldRankBonus()
    // ...
);

// 実行
RankBonus bonusStrategy = rankBonuses.get(userRank);
int bonusPoint = bonusStrategy.getBonus(purchaseAmount);
```
- if (rank == silver) ... else if ...のような分岐の氾濫を防ぎやすい

---

### 2.4 ファーストクラスコレクション
- コレクション（List, Setなど）とその操作ロジックをひとまとめにする
- 不正要素の混入や集計ロジックの散在を防ぎやすい

例：Party（RPGのパーティ）
```java
class Member {
    // ...キャラクター情報...
}

class Party {
    private final List<Member> members;

    Party(List<Member> members) {
        this.members = new ArrayList<>(members);
    }

    // Partyに新規メンバーを追加
    Party add(Member newMember) {
        List<Member> newMembers = new ArrayList<>(members);
        newMembers.add(newMember);
        return new Party(newMembers);
    }

    // Party内に特定メンバーがいるか
    boolean contains(Member target) {
        return members.contains(target);
    }
}
```
- Partyクラスを通じてしかメンバー管理を行わないため、整合性が保ちやすい

---

### 2.5 スプラウトクラス
- 既存クラスを大きく変更せず新機能を新クラスとして追加して動作を差し替える
- レガシーコードや巨大クラスに対して段階的に導入しやすい

---

## 3. 不変（Immutable）と再代入の防止
- finalや新インスタンス返却を徹底することで、オブジェクトの状態が予期せず変わるのを防ぐ

例：攻撃力の強化
```java
class AttackPower {
    static final int MIN = 0;
    final int value;

    AttackPower(int value) {
        if (value < MIN) {
            throw new IllegalArgumentException("攻撃力が負");
        }
        this.value = value;
    }

    AttackPower enhance(AttackPower increment) {
        return new AttackPower(this.value + increment.value);
    }
}

AttackPower base = new AttackPower(10);
AttackPower enhanced = base.enhance(new AttackPower(5));
// baseは変わらず、新しいenhancedが作られる
```
---

## 4. カプセル化による堅牢性向上

バラバラなロジックを散らさない
- UtilsやCommonに何でも置くと、ロジックが分散して保守性を損ねる

生成ロジックを分散しない
```java
// 悪い例：色々な場所でGiftPointをバラバラにnewしている
GiftPoint gp = new GiftPoint(3000);
GiftPoint gp2 = new GiftPoint(10000);
```

```java
// 生成専用メソッドを提供する例
class GiftPoint {
    private GiftPoint(int point) {
        // バリデーション処理
    }

    static GiftPoint forStandard() {
        return new GiftPoint(3000);
    }

    static GiftPoint forPremium() {
        return new GiftPoint(10000);
    }
}
```
参照型引数の破壊を避ける
```java
// 悪い例：呼び出し元のlocationが意図せず書き換わる
void shift(Location location, int dx, int dy) {
    location.x += dx;
    location.y += dy;
}
```

```java
// 良い例：新たなLocationを返す
class Location {
    final int x;
    final int y;
    Location(int x, int y) { this.x = x; this.y = y; }

    Location shifted(int dx, int dy) {
        return new Location(this.x + dx, this.y + dy);
    }
}
```
---

## 5. 関心の分離実践: 単一責任とDRY

### 5.1 単一責任の原則 (SRP)
- 一つのクラスやメソッドが複数の大きな責任を持たない
- 例：MemberManagerクラスに「CSV出力」「会員ランク更新」「メール送信」などが混在しているのはNG

### 5.2 DRY (Don’t Repeat Yourself)
- 同じ意図・同じ実装の重複はまとめる
- ただし、**ビジネス目的が違うのに「似ているだけ」**なケースはむしろ分けておく

### 5.3 継承より委譲
- 継承（extends）は実装の一部が流れ込んでしまい、影響範囲が大きくなる
- Composition (委譲) を優先すると、変更点を小さく保ちやすい
```java
class BasicPhysicalAttack {
    int singleAttackDamage() { return 10; }
}

class FighterPhysicalAttack {
    private final BasicPhysicalAttack base = new BasicPhysicalAttack();

    int singleAttackDamage() {
        // baseに委譲しつつ追加の補正
        return base.singleAttackDamage() + 20;
    }
}
```
---

## 6. 条件分岐の整理

### 6.1 早期returnの活用
```java
// 悪い例：ネストが深い
if (conditionA) {
  if (conditionB) {
    if (conditionC) {
      // 実行
    }
  }
}
```

```java
// 良い例：早期returnで脱出
if (!conditionA) return;
if (!conditionB) return;
if (!conditionC) return;
// 実行
```
### 6.2 switch文・if文の集約
- 同じ種類の分岐をアプリ全体に散らばせない
- enumやinterface + Mapで集約

### 6.3 ストラテジパターンで分岐置換
- 上記2.3を参照

### 6.4 ポリシーパターン
- ルール(Policy)をインターフェースとして定義、複数の実装を切り替え

---

## 7. インターフェース設計
- **「型判定してキャスト」**するのではなく、多態性(interface)で実装を差し替える
- メソッドシグネチャ（引数・戻り値）を揃えておくと呼び出し側が単純化

例：図形の面積を表示
```java
// 悪い例
void printArea(Object shape) {
    if (shape instanceof Rectangle) {
        System.out.println(((Rectangle) shape).area());
    } else if (shape instanceof Circle) {
        System.out.println(((Circle) shape).area());
    }
}
```

```java
// 良い例
interface Shape {
    double area();
}

void printArea(Shape shape) {
    System.out.println(shape.area());
}
```
---

## 8. コレクションの扱い

### 8.1 自前ループを避けてStream活用
```java
// 悪い例
boolean found = false;
for (Item item : items) {
    if (item == target) {
        found = true;
        break;
    }
}
```

```java
// 良い例
boolean found2 = items.stream().anyMatch(item -> item == target);
```
### 8.2 continueやbreakでネスト解消
```java
for (Item item : items) {
    if (!item.isActive()) {
        continue; // アクティブでないものはスキップ
    }
    // 以降はisActive == trueの場合のみ
    processItem(item);
}
```
### 8.3 ファーストクラスコレクション
- 先述の2.4参照

---

## 9. 健全性維持のための一般原則

### 9.1 マジックナンバーの排除
```java
// 悪い例
int timeLimit = currentTime - 60;
```

```java
// 良い例
private static final int TRIAL_PERIOD_SECS = 60;
int timeLimit = currentTime - TRIAL_PERIOD_SECS;
```
### 9.2 グローバル変数を使わない
```java
// 悪い例
public class OrderManager {
    public static int currentOrderId;
}
```
- どこからでもアクセス可能 → 予期せぬ変更の温床

### 9.3 nullを返さない・渡さない
- 代わりに空オブジェクトパターンやOptionalを使う
```java
class Equipment {
    static final Equipment EMPTY = new Equipment("装備なし", 0, 0);
    // ...
}

// 悪い例
if (equipment == null) { ... }
```

```java
// 良い例
if (equipment == Equipment.EMPTY) { ... }
```
### 9.4 パッケージング・レイヤリング
- 技術ドリブン(controller, service, repository)だけでなく、ドメイン観点でフォルダを切る
- 例：domain.model.user, domain.model.product, domain.service.payment 等

---

## 10. 名前設計

### 10.1 目的駆動名前設計
- Productだけでは広すぎる場合、OrderProduct, DeliveryProductなど目的を含める
- 「それは何に使われるクラスなのか？」が明確になる

### 10.2 ~~Manager, ~~Data, ~~Utilは危険
- どんどんロジックが入り大きくなりやすい
- 例：MemberManagerが「CSV保存」「メール送信」「登録更新」を全部持つ → 分割推奨

### 10.3 ロジックをなぞった名前を付けない
```java
// 悪い例: 名前がそのままロジックを表している
boolean isMemberHpMoreThanZeroAndMemberCanActAndMpSufficient() { ... }
```

```java
// 良い例: 意図を表す
boolean canChantMagic(Member member) { ... }
```
### 10.4 メソッド名は動詞1語＋対象の責務を意識
- addArmor(), unequipArmor(), checkArmorState()
- 可能な限り「○○する△△」のような2要素にしない（クラス側で完結できるか再考）

---

## 11. コメント・ドキュメンテーション

### 11.1 コメントの役割と注意点
- 意図を説明し、「なぜこの書き方をしたか」「どんな仕様変更が想定されるか」を補足
- コードの逐次説明は、コード変更でメンテされなくなる恐れがある

### 11.2 「何を」「なぜ」書いたのか
- たとえば「この値は加盟店契約により0円以下にならない」とか「ここの在庫計算は予約在庫分を含む」といった、ビジネスルールや仕様背景に関するコメントが有効

---

## 12. メソッド（関数）の詳細設計

### 12.1 コマンドとクエリの分離
- Query = 値を返すだけ (副作用なし)
- Command = 状態を変更 (戻り値なし or 新インスタンス返却)
```java
// Query
int currentHp() {
    return hitPoint.value;
}
```

```java
// Command
void receiveDamage(int damage) {
    this.hitPoint = this.hitPoint.damage(damage);
}
```
### 12.2 引数の最適化
- finalで引数を変更しない
- フラグ引数（boolean）は複雑化の元 → ストラテジ化する
```java
// 悪い例: フラグ引数
void updateStatus(int memberId, boolean isForcibly) { ... }
```

```java
// 良い例
interface UpdateStatusStrategy {
    void update(int memberId);
}
class NormalUpdate implements UpdateStatusStrategy { ... }
class ForceUpdate implements UpdateStatusStrategy { ... }
```
### 12.3 戻り値の型設計・例外スロー
- エラー時に-1やnullを返さない
- 不正引数は例外を投げて呼び出し側に明示的に通知

---

## 13. リファクタリング

### 13.1 既存コードを壊さないための手順
- ユニットテストを用意してリファクタリング前と後でテストが通ることを保証

### 13.2 条件式の反転・メソッド抽出
- ネストを減らすには「もし不正なら即return」とする
- 重複箇所があるならメソッドにまとめる
- IDEのExtract Method機能やRename機能を活用

### 13.3 機能追加とリファクタリングは分離
- 変更履歴を追いやすくし、バグ混入リスクも減らす

---

まとめ
1. 関心の分離 + カプセル化：クラス・メソッドは「1つの目的」に絞る。
2. 完全コンストラクタ + 不変化：生成時に不正値を防ぎ、生成後の状態破壊を避ける。
3. 条件分岐は早期returnやストラテジパターン・インターフェースでシンプルに。
4. 名前設計はビジネス・仕様が伝わる表現を選ぶ。~~Managerのような曖昧な名前は要注意。
5. コメントは「意図や注意事項」にフォーカスして、仕様変更時に役立つ情報を残す。
6. リファクタリングはテスト体制を整えて安全に進め、機能追加とは別コミットで。

このような設計指針を一つずつ取り入れることで、可読性・保守性・拡張性が高いコードを実現できます。ぜひプロジェクトに合わせて実践してみてください。