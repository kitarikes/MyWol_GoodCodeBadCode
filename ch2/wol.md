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