## 得た知見

### 関心の分離（目的単位でメソッドに分割）

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
