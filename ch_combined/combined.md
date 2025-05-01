# 得た知見

## 【関心の分離】目的単位でメソッドに分割しよう

- 目的単位でメソッド分割

```java
int sumUpPlayerAttackPower(int playerArmPower, int playerWeaponPower) {
    return playerArmPower + playerWeaponPower;
}

int sumUpEnemyDefence(int enemyBodyDefence, int enemyArmorDEfence) {
    return enemyBodyDefence + enemyArmorDefence;
}

int esimateDamage(int totalPlayerAttackPower, int totalEnemyDefence) {
    int damageAmount = totalPlayerAttackPower - (totalEnemyDefence / 2);
    if (damageAmount < 0) {
        return 0;
    }

    return damageAmount;
}
```

- メソッド呼び出し

```java
int totalPlayerAttackPower = sumUpPlayerAttackPower(playerArmPower, playerWeaponPower);
int totalEnemyDefence = sumUpEnemyDefence(enemyBodyDefence, enemyArmorDEfence);
int damage = esimateDamage(totalPlayerAttackPower, totalEnemyDefence);

// メリット：
// - コードの可読性が向上する
// - コードの再利用性が向上する
// - コードの保守性が向上する

// デメリット：
// - メソッド呼び出しのオーバーヘッドが発生する
// - スタックトレースが長くなる
```
QA: 分割しすぎてもIDE上で参照が増えて逆に見にくいのでは？

## 【カプセル化】データとそのデータを操作するロジックを閉じ込める

```java
class HitPoint {
    private static final int MIN = 0;
    private static final int MAX = 999;
    private static final int MIN_DAMAGE_AMOUNT = 0;
    private static final int MIN_RECOVERY_AMOUNT = 0;
    final int value;

    HitPoint(final int value) {
        if (value < MIN ) {
            throw new IllegalArgumentException("ヒットポイントは" + MIN + "以上を指定しください");
        }
        if (MAX < value) {
            throw new IllegalArgumentException("ヒットポイントは" + MAX + "以下を指定してください")
        }
        this.value = value;
    }

    // ダメージを受ける
    HitPoint damage(final int damageAmount) {
        if (damageAmount < MIN_DAMAGE_AMOUNT) {
            throw new IllegalArgumentException("ダメージ量は" + MIN_DAMAGE_AMOUNT + "以上を指定してください");
        }

        final int damaged = value - damageAmount;
        final int coreccted = damaged < MIN ? MIN : damaged;
        return new HitPoint(corrected);
    }

    // 回復する
    HitPoint recover(final int recoveryAmount) {
        if (recoveryAmount < MIN_RECOVERY_AMOUNT) {
            // throw new ...
        }

        final int recovered = value + recoveryAmount;
        final int correced = Max < recovered ? MAX : recovered;
        return new HitPoint(corrected);
    }
}
```

使用例

```java
public class GameDemo {
    public static void main(String[] args) {
        // ① キャラクターを HP150 で生成
        HitPoint hp = new HitPoint(150);
        System.out.println("[Start]  HP = " + hp.value);
        
        // ② 敵から 35 ダメージを受ける
        hp = hp.damage(35);
        System.out.println("[Damage] HP = " + hp.value);

        // ③ ポーションで 25 回復する
        hp = hp.recover(25);
        System.out.println("[Heal]   HP = " + hp.value);

        // ④ 必殺技で 999 ダメージ → 最小値 0 で下限に張り付く
        hp = hp.damage(999);
        System.out.println("[KO]     HP = " + hp.value);
    }
}
```
# カプセル化
- クラスを作成する時は、そのクラスのみで動作するように設計する。
- 他の前準備をしなければ使えないようなクラスを設計しない！
- データクラス自身で属するデータを守る仕組みを持つ。

## 【値の渡し間違いを防ぐ】引数に型を指定する（intやString）
```java
class Money {
    // 省略
    Money add(final Money other) {
        final int added = amount + other.amount;
        return new Money(added, currency);
    }
}
```

## クラス構築におけるチェックリスト

ドメインモデルの完全性 =「値が正確な状態を維持していること」をクラス構築では目指す！

- ① 必要なロジックをデータクラスに集約する
    - 修正漏れを防ぐ
    - 可読性向上
- ② コンストラクタでインスタンス変数の値を確定させる
    - 不正値が入った場合は例外を出す
- ③ finalで変数を不変にする
    - 不正値の混入を防ぐ
- ④ メソッドの引数に型を指定する
    - 純粋なint型の入力等を防ぐ


```java
import java.util.Currency;

// ① 必要なロジックをデータクラスに集約する
class Money {
    // ③ finalで変数を不変にする
    final int amount;
    final Currency currency;

    Money(final int amount, final Currency currency) {
        // ② コンストラクタでインスタンス変数の値を確定させる
        if (amount < 0) {
            // throw ~~
         }
        if (currency == null) {
            // throw ~~
        }

        this.amount = amount;
        this.currency = currency;
    }

    Money add(final Money other) {
        // ④ メソッドの引数に型を指定する
        if (!currency.equals(other.currency)) {
            // thorw ~~
        }

        final int added = amount + other.amount;
        return new Money(added, currency);
    }
}
```


# 設計パターン

- 完全コンストラクタ
    - 不正状態から防護する
- 値オブジェクト
    - 値に関するロジックをカプセル化
- ストラテジ
    - 条件分岐を削減し、ロジックを単純化
- ポリシー
    - 条件分岐を単純化したり、カスタマイズしたりできるように
- ファーストクラスコレクション
    - コレクションに関するロジックをカプセル化する
- スプラウトクラス
    - 既存ロジックを変更せずに安全に新機能を追加する

## 完全コンストラクタ（前述のHP計算、Moneyの例）

不正状態から防護する設計パターン。

1. インスタンス変数を全て初期化できる引数を持ったコンストラクタを用意する。
2. コンストラクタ内のガード節で防護する。
3. よって、生成時に正常値だけを持つ完全なインスタンスが生成される。
4. さらに、finalで不変にし、生成後に不正状態にならないようにする。

## 値オブジェクト（前述のMoneyの例）

値に関連するロジックを一箇所に集めカプセル化する。

- 課題感: 例えば、金額をローカル変数や引数で管理してると、計算ロジックがバラバラに書かれてしまう。
- また、同じint型の値が金額用の変数に不注意に代入されてしまう可能性もある。

1. コンストラクタに値の概念（0円以上）を定義する。
2. ロジックはクラス内に集約する。
3. メソッドの引数は「値クラス」のみを取るようにする。


値オブジェクトとして設計可能な例

- ECサイト：税別金額、税込金額、商品名、注文数、電話番号、配送元、配送先、割引ポイント・・
- タスク管理：タスクタイトル、タスク説明、コメント、開始日、期日、優先度、進捗状態、担当者ID、担当者名・・

# 「完全コンストラクタ＋値オブジェクト」はカプセル化の最も基本的な設計パターン
# 再代入

## 不変にして再代入を防ぐ

「finalをつけることで不変にし、変数の命名を都度行う」

```java
int damage() {
    final int basicAttackPower = member.power() + member.weaponAttack();
    final int finalAttackPower = (int)(basicAttackPower * (1f + member.speed() / 100f));
    final int reduction = (int)(enemy.defence / 2);
    final int damage = Math.max(o, finalAttackPower - reduction);

    return damage;
}
```

## 引数も不変にする

`final int productPrice`により、引数自体を更新しないようにする。

```java
void addPrice(final int productPrice) {
    final int increasedTotalPrice = totalPrice + productPrice;
    // 略
}
```

## オブジェクトの使い回しを避ける

「外部に影響力を持たないような更新を行う → 値が変わるごとに初期化して、オブジェクトを返す → 使い回しを避ける！」

```java
class AttackPower {
    static final int MIN = 0;
    final int value;

    AttackPower(final int value) {
        if (value < MIN) {
            // throw ~~
        }

        this.value = value;
    }

    // 攻撃力を強化する
    AttackPower enhance(final AttackPower increment) {
        return new AttackPower(this.value + increment.value);
        // 値が変わるごとに初期化して、オブジェクトを返す → 使い回しを避ける！
    }
}
```

## 正しく状態変更するメソッドを設計する

状態変更をする時は、不正な値が入らないような仕組みを、値クラス側で持つ！

```java
// HitPointクラス
class HitPoint {
    private static final int MIN = 0;
    int amount;

    HitPoint(final int amount) {
        if (amount < MIN) {
            throw new IllegalArgumentException();
        }

        this.amount = amount;
    }

    void damage(final int damageAmount) {
        final int nextAmount = amount - damageAmount;
        amount = Math.max(MIN, nextAmount);
    }

    boolean isZero() {
        return amount == MIN;
    }
}

class Member {
    final HitPoint hitpoint;
    final States states;
    // 中略

    void damage(final int damageAmount) {
        // hitPoint.amount -= damageAmount; のように0以下の値が入る可能性を防ぐ！
        hitPoint.damage(damageAmount);
        if (hitPoint.isZero()) {
            states.add(StateType.dead);
        }
    }
}
```
# バラバラなデータとロジックをカプセル化する
## int等のプリミティブな値を引数とせず、型を作る

そうすることで、その値に関する条件分岐を色んな場所に散在しなくて済む。

```java
// 値に関するロジックが散在している
class Util {
    boolean isFairPrice(int regularPrice) {
        if (regularPrice < 0) {
            throw new IllegalArgumentException();
        }
    }

    int discountedPrice(int regularPrice, float discountRate) {
        if (regularPrice < 0) {
            throw new IllegalArgumentException();
        }
        if (discountRate < 0.0f) {
            throw new IllegalArgumentException();
        }
    }
}
```

```java
// 型として存在する限り、正常な値が入っていることが保証されるため、if文を都度書く必要がない
class RegularPrice {
    final int amount;

    RegularPrice(final int amount) {
        if (amount < 0) {
            throw new IllegalArgumentException();
        }
        this.amount = amount;
    }
}
```

## staticメソッドを誤用しない

staticメソッドはインスタンスを生成しなくても使えるメソッド。そのため、データとロジックがバラバラになる可能性がある。

## 生成ロジックを分散しない

コンストラクタを公開すると、多様な初期化ロジックが、色々な場所で記述される可能性がある。

```java
GiftPoint standardMemberShipPoint = new GiftPoint(3000);
GiftPoint premiumMemberShipPoint = new GiftPoint(10000);
```

↓ 生成ロジックが増える&使い回しそうな時は、コンストラクタをprivateにする

**ファクトリクラス！**：このように、コンストラクタを公開せず、初期化するメソッドをstaticで公開する設計もある。

```java
class GiftPoint {
    private static final int MIN_POINT = 0;
    private static final int STANDARD_MEMBERSHIP_POINT = 3000;
    private static final int PREMIUM_MEMBERSHIP_POINT = 10000;
    final int value;

    // 外部からはインスタンス生成できない。
    // クラス内部でのみインスタンス生成できる。
    private GiftPoint(final int point) {
        if (point < MIN_POINT) {
            // throw ~~
        }
        value = point;
    }
}

static GiftPoint forStandardMembership() {
    return new GiftPoint(STANDARD_MEMBERSHIP_POINT);
}

// ・・・
```

## 共通処理クラスにロジックを雑多に置かない

値に関連するロジックは、その値クラスとしてカプセル化すべき。

ただ横断的な関心ごとはstaticメソッドとして、共通処理としても良い

ログ出力、エラー検出、デバッグ、分散処理、同期処理、キャッシュ、例外処理

## 参照型引数をメソッド内で更新しない

```java
class ActorManager {
    void shift(Location location, int shiftX, int shiftY) {
        location.x += shiftX;
        location.y += shiftY;
    }
}
```

課題感：
- Locationにデータクラス、ActorMaangerにロジックがあり、関心が分離
- location自体を内部で更新。どう更新しているかはクラスメソッドを見に行くまでブラックボックス

↓

- 引数自体を更新せず、移動後のインスタンスを返すようにする。

```java
class Location {
    final int x;
    final int y;

    Location(final int x, final int y) {
        this.x = x;
        this.y = y;
    }

    Location shift(final int shiftX, final int shiftY) {
        final int nextX = x + shiftX;
        final int nextY = y + shiftY;
        return new Location(nextX, nextY);
    }
}
```

## 引数が多すぎる時は処理が膨らんでいる証拠

引数ではなくインスタん変数として定義する。

```java
class MagicPoint {
    // 現在の魔法力残量
    int currentAmount;
    // オリジナルの魔法力最大値
    int originalMaxAmount;
    // 魔法力最大値の増分
    List<Integer> maxIncrements;
}
```

魔法力に関係するロジックはカプセル化

- currentAmountやoriginalMaxAmountをインスタンス変数にして、メソッドの引数を減らす！

```java
class MagicPoint {
    private int currentAmount;
    private int originalMaxAmount;
    private final List<Integer> maxIncrement;

    int current() {
        return currentAmount;
    }

    int max() {
        int amount = originalMaxAmount;
        for (int each : maxIncrements) {
            amount += each;
        }
        return amount;
    }

    void recovery(final int recoveryAmount) {
        currentAmount = Math.min(currentAmount + recoveryAmount, max());
    }
}
```

## アクセス連鎖を避けよう（objを.で繋ぐな！）

インスタンス変数に対して数珠つなぎにアクセスするのはやめろ！

- `party.members.get(memberId).equipments.canChange`最悪の数珠繋ぎだ！

```java
void equipArmor(int memberId, Equipment newArmor) {
    if (party.members.get(memberId).equipments.canChange) {
        // function()
    }
}
```

ソフトウェア設計には「**尋ねるな、命じろ！**」という言葉がある！

```java

class Equipments {
    private boolean canChange;
    private Equipment head;
    private Equipment armor;
    private Equipment arm;

void equipArmor(final Equipment newArmor) {
    if (canChange) {
        armor = newArmor;
    }
}

void deactivateAll() {
    head = Equipment.EMPTY;
    armor = Equipment.EMPTY;
    arm = Equipment.EMPTY;
}
}
```
# 関心の分離

## 目的ごとに関心を分離して、カプセル化する

クラスの目的以外の知識/概念を記述しない

```java
class SellingPrice {
    // 販売価格以外の知識/概念を記述しない
}

// ↓ 追加で

class SellingCommission {
    // 販売手数料クラス
}

class DeliveryCharge {
    // 配送料クラス
}
```

# 関心の分離を実践する

## 単一責任の原則
- クラスは外のクラス/ロジックに責任を持つべきでない

## DRY原則
- 似て非なるコードをひとまとめにしない
- 目的が異なれば、重複しても、別々に記述すべき
- 重要なのは、ビジネス観点で目的が同じかどうか

## 継承より委譲 コンポジション構造

委譲の例

```java
class FighterPhysicalAttack {
    private final PhysicalAttack physicalAttack;
    // 略
    int singleAttackDamage() {
        return physicalAttack.singleAttackDamage() + 20;
    }
}
```

# 条件分岐

## 早期return: else句は使わない

↓のように書くとネストしなくて可読性/変更容易性○

```java
if (~~~) return;
if (~~~) return;
if (~~~) return;
if (~~~) return;
if (~~~) return;
```


## switch文は一箇所にまとめる！重複させない！

```java
switch (type) {
    type.STUDENT : 
        // ~~~
    type.EMPLOYEE :
        // ~~~
}

// のようなスイッチ文をいたる所に書いてませんか？
```

## switch文よりもinterface！多態性 → 条件分岐と同じことが実現できる！

条件分岐で型を特定し、機能を切り替える仕組みから、interfaceで機能を取り替える仕組みにできる！

適用前：if文で型を特定し、キャストした上でメソッドを使用する必要がある。

```java
void showArea(Object shape) {
    if (shape instanceof Rectangle) {
        System.out.println(((Rectangle) shape).area());
    }
    if (shape instanceof Circle) {
        System.out.println(((Circle) shape).area());
    }
}
```

適用後：interfaceを実装しているクラスは全て引数として取れる！

```java
interface Measurement {
    double area();
}

void showArea(Measurement measurement) {
    System.out.println(measurement.area());
}
```

## ストラテジパターン 〜interface + enum + Mapで機能を切り替える〜

```java
interface MagicAttack {
    String name();
    int costMagicPoint();
    int attackPower();
}

final Map<MagicType, MagicAttack> magickAttacks = Map.of(
    MagicType.fire, new Fire(member),
    MagicType.shoden, new Shiden(member),
    MagicType.hellFire, new HellFire(member)
);

void attack(final MagicType magicType) {
    final MagicAttack usingMagicAttack = magicAttacks.get(magicType);
    usingMagicAttack.attackPower();
}

attack(MagicType.fire);
```

# interfaceの設計の考え方を身につける

例：
- 毎年7月1日に、ノーマルをのぞく特定ランクの会員に対し、年間ボーナスポイントが還元する
- ポイント還元はランクごとに異なる
  - シルバーの場合、過去１年間の購入費が10万円以上の場合、過去１年間の購入費の１％をポイントとして還元する
  - ゴールドの場合、１０００ポイントと、過去１年間の購入費の２％をポイントとして還元する

```
if today == "*0701" and user != normal:
    if user == silver and money >= 100000:
        point += money*0.01
    else if user == gold:
        point += 1000 + money*0.02
```

## 流れ① 機能を取り替える単位を見つける
- ノーマル → なし
- シルバー → 過去1年間の購入者が10万円以上の場合、過去１年間の購入費の1%をポイントとして還元
- ゴールド → 1000ポイント ＋ 過去１年間の購入費の２％を還元

## 流れ② 結果と入力が同じかどうかを確認する
- 結果：年間ポイントボーナス
- 入力：過去１年間の購入費の2％を還元

```java
interface CustomerBenefit {
    ShoppingPoint yearlyPointBonus(final PurchaseHistory history);
}

class NormalCustomerBenefit implements CustomerBenefit {
    public ShoppingPoint yearlyPointBonus(final PurchaseHistory history) {
        return new ShoppingPoint(0);
    }
}

class SilverCustomerBenefit implements CustomerBenefit {
    public ShoppingPoint yearlyPointBonus(final PurchaseHistory history) {
        return new ShoppingPoint(100);
    }
}

class GoldCustomerBenefit implements CustomerBenefit {
    public ShoppingPoint yearlyPointBonus(final PurchaseHistory history) {
        return new ShoppingPoint(1000);
    }
}

// クラスごとの還元率オブジェクトを動的に返すためのクラス
class CustomerBenefits {
    CustomerBenefits() {
        benefits = Map.of(
            Rank.normal, new NormalCustomerBenefit(),
            Rank.silver, new SilverCustomerBenefit(),
            Rank.gold, new GoldCustomerBenefit()
        )
    }

    CustomerBenefits select(final CustomerRank customerRank) {
        return benefits.get(customerRank);
    }
}

// if文/switch無しで書ける！
// Rankを引数にしてランクに対応した還元率オブジェクトを返す
final customerBenefit = new CustomerBenefits().select(customerRank);
// 還元率オブジェクトでボーナスポイントを取得するメソッドを呼び出す
final ShoppingPoint yearPointBonus = customerBenefit.yearPointBonus(purchaseHitory);
```

## ポリシーパターン

- バリデーションロジック -> boolean をinterfaceで集約して、for文でバリデーションチェックする。
- Rule型をaddで集約してfor文でチェックする。

```java
interface ExcellentCustomerRule {
    boolean ok(final history);
}

class GoldRule implements ExcellentCustomerRule {
    ok(history) {
        return // 条件式
    }
}

// ・・・
```
## 型判定はしない！

- 使うな！instanceof！

## interfaceを使いこなせるかが設計力を左右する

# コレクション

## 自前でコレクションを実装しない！

↓ は stream().anyMatchで書ける！ネストが深くなるのでやめよう！

```java
for (Item item : items) {
    if (item == target) {
        frag = true;
        break;
    }
}
```

## 条件分岐ネストはcontinueで解消できる！

- 即 `if () return;`と同じ！
- 即 `break`も！使う！

## コレクションをカプセル化する〜ファーストコレクション〜

※ ただのコレクションカプセル化

```java
class Party {
    final List<Member> members;

    Party() {
        members = new ArrayList<Member>();
    }

    private Party(List<Mmeber> members) {
        this.members = members;
    }

    Party add(final Member newMember) {
        final List<Member> adding = new ArrayList<>(members);
        adding.add(newMember);
        return new Party(adding); // getter/setterを設定せずに、更新後のオブジェクト自体を返す！
    }
}
```
# 設計の健全性を失わないために

## マジックナンバーを使わない

必ず定数として定義しておく！

```java
int tmp = value - 60;

// ↓ private static final で変数定義しておく

private static final int TRIAL_READING_POINT = 60;
```

## グローバル変数を使わない

static変数をpublic宣言すると、グローバルアクセス可能になってしまう。

```java
public OrderManager {
    public static int currentOrderId;
}
```

## nullを返さない！渡さない！代入しない！

- EMPTYという状態（インスタンス）を定義しておき、空の場合はそれを代入する。
- 常にインスタンスが存在するようにしておく。

```java
class Equipment {
    static final Eqipiment EMPTY = new Equipment("装備なし", 0, 0, 0);
    // ~~~
}

void takeOffAllEquipments() {
    head = Equipment.EMPTY;
    body = Equipment.EMPTY;
    arm = Equipment.EMPTY;
}
```

## リフレクション？ = 動的にコード自体を生成するようなロジック

## 技術駆動パッケージングは、本来強く関係し合うロジックをバラバラにさせる

- TODO: Javaのディレクトリ構成を確認しよう

## パターンを用いるにあたっての注意点！

- デザインパターンを無理に使おうとして、かえって変更が難しくなってしまうことがある

本書は、
- コード変更を楽にするのが目的
- → 仕様があまり変更されない箇所
- → 実験的に開発したプロトタイプ
- → 寿命が間近のサービス
- は効果を発揮しない。

パターンは手当たり次第に適用しない！
# 名前設計 - あるべき構造を見破る名前 -

## 【重要】目的駆動名前設計!!

- 名前から目的や意図が読み取れることを重視
- 単一責任を守る設計


## 悪魔を呼び寄せる名前（関心を分離しよう）

- 商品クラスとして作るのは意味が広すぎないか？

↓

- 予約品
- 注文品
- 在庫品
- 発送品

のように目的別にクラスを分割する（関心の分離）

商品だけだと、目的がわからない！

## 目的駆動名前設計の注意点

- 可能な限り具体的で、意味が狭い、目的に特快した名前を選ぶ
- 存在駆動ではなく、目的駆動で名前を考える（解像度が高い名前に）
  - 存在駆動 → ユーザーは、法人なのか、個人なのか、目的が違う
- どんな業務目的があるのか分析する
- 声に出して話してみる
- 利用規約を読んでみる
  - 利用規約には意図が明確な言葉があるのでヒントに
- 違う名前に置き換えられないか検討する
  - 顧客 → 宿泊する人 + 支払う人 に分けて設計するなど
- 関心が分離されているか点検する

## 既存クラスの構造改善を促す問い

- このクラスの正体は何ですか？実は全然別の概念である可能性がないか？
- このクラスの目的は何ですか？また、何をもって目的を達成したとみなすのか教えてください。

## 技術駆動命名はやめよう

- memory, cache, thread, ...
- function, method, class, ...
- int, str, flag, ...

ハードウェアに近いレイヤーでは技術駆動命名になることもある！

## ロジックをなぞった名前をつけない

- 以下は、内部のロジックをなぞった命名になっている！
- 実は、魔法を唱えられるかチェックしたいだけ！

```java
class Magic {
    boolean isMemeberHpMoreThanZeroAndIdMemberCanActAndIsMemberMpMoreThanMagicCostMp(member) {
        // ~~~
    }
}

// ↓

class Magic {
    boolean canChant(final Member member) {
        // ~~~
    }
}
```

## ~~Managerという名前を命名しない！

```java
class MemberManager {
    int getHitPoint() {
        // ~~~
    }

    void exportCsv() {
        // ~~~
    }

    // 巨大化していく
    // 関心の分離をしにくい名前
}
```

## 文脈によって意味や扱いが異なる名前

- Carクラス
    - 配送元
    - 配送先
    - 配送経路
    - 販売価格
    - 販売オプション 

↓ 文脈ごとに設計し直す

- 配送パッケージ
    - Carクラス
        - 配送元
        - 配送先  
        - 配送経路
    - 配送先選択
- 販売パッケージ
    - Carクラス
        - 販売価格
        - 販売オプション
    - 注文

このように文脈によって最上段の目的を分割することができる

## 動詞＋目的後のメソッド名をつけない

- アンチパターン：`addItemToParty`をEnemyクラスに実装する

```
〜〜を〇〇にする というメソッドは、
自身の関心外のロジックを混入させるきっかけとなる
```

- メソッド命名は動詞1語にするべき
    - PartyItemsクラスを作って、`add`メソッドを実装する

## メソッド命名は、クラス名 ＋ 動詞 にしてみて違和感がないか？

- `isHungry`メソッドの場合
- ❌ Commonクラス is hungry
- ◎ Memberクラス is hungry

## エディタで補完できるから、変数名は省略しない！


# コメントの書き方

## コメントを読まれるのは、保守と仕様変更時

- ロジックの目的や意図を説明する
- 何に注意すれば安全に仕様変更できるのか

を記述する！
# メソッド（関数）

## Getter, Setterの実装により、オブジェクトを同時に変更される可能性があり❌

## コマンドとクエリは分割しよう

- 取得メソッド
- 更新メソッド

は分割する

## 引数

- 引数は不変`final`にする
- フラグ引数は使わない → ストラテジパターンを使う
- nullを渡さない → Obj.Emptyを実装する
- 出力引数（objectを引数として渡して、変更後のobjectを返す）
- 引数は少なくする（多い場合は関心の分離ができていない可能性ある）

## 戻り値

- 型を指定する（プリミティブを返さない）
- 金額にも目的ごとに型を設定できるはず

```java
Price price = productPrice.add(otherPrice);
DiscountedPrice discountedPrice = new DiscountedPrice(price);
DeliveryPrce = deliveryPrice = new DeliveryPrice(discountedPrice);
```

## エラーを戻り値で返さない

- コンストラクタ内でバリデーションを実施して、例外をスローする！
- -1 や、Location のように値を返さない

```java
// ~~
return new Location(-1, -1);

// ↓

Location(final int x, final int y) {
    if(!valid(x, y)) {
        throw ~~
    }
}

Location shift() {
    return new Location(nextX, nextY);
}
```


# モデリング -クラス設計の土台-

モデル = 特定の目的達成のために最低限考慮が必要な要素を備えたもの

目的ごとに定義した商品モデル

- 注文時の商品
    - ID
    - 商品名
    - 売値
    - 在庫数
- 配送時の商品
    - ID
    - サイズ
    - 重量

## モデルと実装は必ず相互にFBする

モデル → UMLクラス図を作成

## モデリングよくわかってない

具体、抽象でうまく構造化する感じか？
# リファクタリング -既存コードを成長に導く-

= 外から見た挙動を変えずに、構造を整理すること

## if文の条件を反転させてネストを解消する

## 意味のある単位にロジックをまとめる

## 条件を読みやすくする → 論理否定 ! を使わない！

## 条件判定メソッドを用意しておき、それを呼び出す

## 安全にリファクタリングする方法
- テストを書いてTDDすることで安全にリファクタリングができる
- → 機能を壊さないままコード改修が可能


## tips: IDEの機能でRefactor -> method extract
メソッド化できる！

## リファクタリングにおける注意点
- 機能追加とリファクタリングを同時にやらない！
- コミットはどうリファクタリングしたかがわかる粒度で！
    - メソッド名の変更、ロジックの移動 を分けてコミットする
- 無駄な仕様は削除する


## 疑問：
- リファクタリングがしやすい、クラス間の依存関係を出力できるようなIDE（拡張機能）はあるのか？

