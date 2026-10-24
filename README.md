# DEAD FREIGHT / 失落货场

完全独立的 **Godot 4.6.3 标准版**单人搜打撤 FPS 原型。

## 免费素材画质样片

这一版先验证一小段：**第 1 名敌人**换为 Unvanquished 的带纹理、分件护甲和骨骼动画人物；其他敌人保留原模型作比较。第一人称替换为社区的手臂/步枪，并接入射击、换弹及治疗动画。仓库增加结构、管线、电箱与货架道具，降低环境补光。

[敌人升级前](docs/before-contact.png) · [升级后](docs/contact.png) · [仓库升级前](docs/before-warehouse.png) · [升级后](docs/warehouse.png) · [瞄准](docs/aiming.png) · [换弹动作](docs/reloading.png)

这是免费素材整合的第一轮样片，人物装备仍偏科幻，手臂和武器仍偏简化风格，尚未完成全场景写实美术统一。新人物衍生素材采用 CC-BY-SA；社区第一人称资源另有禁止转售原始素材的条款，完整说明在 assets/ATTRIBUTION.md。

## 立即运行

使用 Godot 4.6.3 打开本目录 `project.godot`，等待首次导入，按 **F6/F5**，点击 **DEPLOY** 开始。
不需要旧项目、C#、插件、账号或联网下载。Windows/macOS 可以直接用 Godot 编辑器打开。

Linux：

```bash
cd /workspace/extraction-prototype
./tools/run.sh
```

脚本把配置、导入缓存之外的用户数据放在本项目 `.runtime/` 下；直接从编辑器启动时，Godot 使用独立的 `dead-freight-prototype` 用户目录。没有引用、复制或修改 `/workspace/godot` 中的代码、素材或存档，两者可分别打开和运行。此项目使用完全独立的 Git 仓库：https://github.com/2459654640-ship-it/dead-freight-prototype ，不关联旧项目的 Git 历史。

## 玩法

在约 70 × 66 米工业货场中开始一局 12 分钟行动。地图含室外装卸区、货架仓库、医务及行政室，建筑有实体墙、屋顶和可通过的入口。

- 五名武装 AI 从十个预设点随机、无重复出生；巡逻、听声调查、发现玩家后追击及射击，视线受实体墙遮挡。敌人使用导入的人物模型和行走动画。
- 一把 5.56 毫米自动卡宾枪，30 发弹匣、90 发备用弹；腰射/移动散布、右键瞄准、后坐力、枪口火光、命中提示、弹痕、换弹计时和实录枪声。命中头部伤害更高。
- 加速与刹停、冲刺体力、跳跃、蹲下、鼠标瞄准、视野缩放、轻微武器摆动。暂停菜单可调鼠标灵敏度。
- 按住 F 搜索物资箱或阵亡敌人的背包；背包 16 个堆叠槽、24 kg 重量限制，可逐项或一键转移、使用和丢弃。
- 绷带治疗需要 2.8 秒，受伤会打断；饮水恢复体力。电子元件、合金、加密硬盘可带出换钱。
- 到地图东北的绿色 **NORTH GATE** 区域停留六秒撤离。成功后整包物资折算入账户并保存；死亡或超时丢失当局物资。每局重新提供基础装备。暂停安全，开背包时世界继续运行。

| 操作 | 按键 |
|---|---|
| 移动 / 观察 | WASD / 鼠标 |
| 射击 / 瞄准 | 鼠标左键 / 按住右键 |
| 冲刺 / 蹲下 / 跳跃 | Shift / Ctrl / Space |
| 换弹 / 治疗 | R / 4 |
| 搜索 | 靠近并看向箱子，按住 F |
| 背包 / 关闭背包 | Tab |
| 地图 | M |
| 暂停 / 返回 | Esc |
| 全屏 | F11 |

## 画面与素材

采用实拍 PBR 沥青、混凝土及砖墙，HDR 天空、带阴影的日光、冷暖室内灯、工业模型、已绑定的人物动画和现成武器；渲染采用 OpenGL Compatibility，便于普通显卡运行。素材随项目保存。

免费素材来源和授权见 [assets/ATTRIBUTION.md](assets/ATTRIBUTION.md)。主要来源：ambientCG、Poly Haven、Quaternius、Flat Guns、Godot TPS Demo；使用 CC0 或 CC-BY 3.0，必要的原始许可和署名已随包保留。没有使用带非商业限制的 GDQuest 美术。

实际运行截图：[室外](docs/yard.png) · [仓库](docs/warehouse.png) · [敌人](docs/contact.png) · [背包](docs/inventory.png)。截图来自 X11 + Mesa llvmpipe 的真实 OpenGL 帧，不用于承诺玩家显卡帧率。

## 开发与验证

```bash
./tools/test.sh
```

测试使用 `.runtime/test/` 下独立存档，不碰玩家档案。检查真实场景中的移动、地面碰撞、蹲下、子弹命中、AI 视线遮挡、换弹守恒、治疗中断、搜刮、防重复拾取、容量/重量、撤离持久化和死亡损失。

| 文件 | 用途 |
|---|---|
| `scripts/raid.gd` | 地图、随机出生、寻路网格、撤离与账户 |
| `scripts/operator.gd` | 玩家移动、视角、武器、治疗和搜索 |
| `scripts/guard.gd` | AI 视线/听觉/状态、战斗、人物动画 |
| `scripts/bag.gd` | 物品、堆叠、容量及重量 |
| `scripts/interface.gd` | HUD、背包、地图、暂停与结算 |
| `scripts/kit.gd` | 网格及素材实例化、PBR 材质 |
| `scripts/sound.gd` | 枪声、脚步与交互音效 |

这是可玩的第一版原型：单人、单张地图、一种枪械；没有联网、弹道穿透、复杂枪械改装、肢体伤害、局外交易界面或完整剧情。人物和部分道具是简化美术，动画以行走和程序化武器动作为主。射击与移动参数已经实现并通过功能检查，主观手感仍需实机鼠标体验调整。
