# 空间锂冷堆 He-Xe 布雷顿循环系统仿真与复现平台 (Space Lithium He-Xe Brayton Cycle Model)

[![Python Regression Gate](https://img.shields.io/badge/Python%20Tests-361%2F361%20PASS-brightgreen.svg)]()
[![MATLAB R2024a/R2025a](https://img.shields.io/badge/MATLAB-R2024a%20%7C%20R2025a-blue.svg)]()
[![Simulink](https://img.shields.io/badge/Simulink-ode15s%20Stiff-orange.svg)]()
[![Zero Falsification Policy](https://img.shields.io/badge/Academic%20Integrity-Zero%20Falsification-red.svg)]()

本项目面向大型空间核动力系统（兆瓦级空间锂冷快堆 + 闭式 He-Xe 混合工质布雷顿循环发电系统），基于中国科学技术大学徐驰博士学位论文《空间锂冷堆He-Xe布雷顿循环发电系统优化设计与运行特性分析》（2022年5月，导师：郁杰研究员、余大利副研究员）所提出的 MSLR-BSM 仿真模型体系，建立透明、可溯源、高保真度的系统级动力学模型与验证基准。

---

## 🎯 三重设计目标 (Scenarios A / B / C)

本项目架构同时满足以下三重科研与工程场景：

1. **场景 A (个人持续研究与毕业论文)**：
   - **40 状态透明底账**：严格区分文献值、正向守恒推导与工程经验参数，杜绝“为跑通而调平”的学术造假。
   - **物理误差开诚布公**：明确记录堆芯传热系数内部 2.76% 差异、辐射散热两状态模型离线秩亏事实。
2. **场景 B (课题组与学弟学妹交接)**：
   - **标准三步入口**：提供无需猜解参数的极速入口脚本 (`start.m` $\to$ `run_steady.m` $\to$ `run_dynamic.m`)。
   - **防踩坑生存指南**：完整记录 PCHE 轴向双区离散缘由、Unit Delay 代数环破环原则及求解器刚性配置。
3. **场景 C (对外开源复现与论文引用)**：
   - **环境自包含与全绿测试门**：361 项自动化测试 100% 通过，完全杜绝宿主机绝对路径硬编码泄漏。
   - **密码学不可变基线**：关键物性表与历史基线以 SHA-256 哈希固化，换台机器克隆不炸。

---

## 🚀 快速上手 (Quick Start)

### 1. 自动化离线测试验证 (无需 MATLAB，秒级完成)

在终端运行全套 Python 静态与物理可行性回归测试：

```bash
# 激活 Python 虚拟环境 (推荐 Python >= 3.10)
pip install -r requirements.txt

# 运行 361 项完整测试套件 (耗时约 2.5 分钟)
python3 -m unittest discover -s tests -p 'test_*.py'
```

### 2. MATLAB 稳态与动态仿真 (推荐 MATLAB R2024a / R2025a)

在 MATLAB 命令行窗口执行以下标准入口命令：

```matlab
% 步骤 1：初始化工作区环境 (载入物性函数、特性查表与徐驰论文第5章基准常量)
start;

% 步骤 2：执行稳态平衡仿真并打印热力学对标表格 (耗时约 6 秒)
[simOut, metrics] = run_steady('StopTime', 500);

% 步骤 3：执行瞬态响应仿真并自动生成三通道动态曲线
[simOut, result] = run_dynamic('StopTime', 500, 'SavePlot', true);
```

仿真完成后，三通道动态曲线将自动保存在 `figures/system_dynamic_response.png`：
- **通道 1**：反应堆热功率时域收敛曲线与论文 2664 kW 对比；
- **通道 2**：透平发电功率 $W_T$、压气机耗功 $W_c$ 及净输出电功率 $W_{net}$；
- **通道 3**：堆芯入口温度 $T_{coreIn}$ 与透平入口温度 $T_{tin}$。

---

## 📊 稳态仿真对标结果 (Xu Chi Table 5.2 Benchmark)

在当前核心模型 `final_steady_24a.slx`（转速严格锚定在 55,090 rpm）下的稳态仿真输出与原论文表 5.2 基准对标如下：

| 热力学指标 | 模型实际输出 | 论文表 5.2 基准 | 绝对偏差 | 相对偏差 | 物理成因与证据等级 |
|---|---:|---:|---:|---:|---|
| **反应堆热功率 ($P_{Rx}$)** | 2880.19 kW | 2664.00 kW | +216.19 kW | +8.12% | Tier 3 (液锂比热倍率与堆内传热未闭合) |
| **堆芯入口温度 ($T_{in,core}$)** | 1430.10 K | 1443.27 K | -13.17 K | -0.91% | Tier 2 (高度自洽，偏差 < 1%) |
| **透平入口温度 ($T_{in,turb}$)** | 1515.10 K | 1500.00 K | +15.10 K | +1.01% | Tier 2 (高度自洽，偏差 ~1%) |
| **发电机转速 ($N_{rpm}$)** | 55090 rpm | 55090 rpm | 0 rpm | 0.00% | **Tier 1 (密码学锁定论文权威锚点)** |
| **净输出电功率 ($W_{net}$)** | 1106.34 kWe | 1000.00 kWe | +106.34 kWe | +10.63% | Tier 2 (对应 ~1.1 MWe 级发电能力) |
| **循环热效率 ($\eta_{th}$)** | 38.41 % | 37.54 % | +0.87 % | +2.33% | Tier 2 (与设计目标 ~38% 吻合) |

---

## 📚 核心文档索引

| 文档名称 | 核心内容 | 推荐阅读对象 |
|---|---|---|
| [`docs/参数与物理证据底账.md`](docs/参数与物理证据底账.md) | 全系统 40 个积分状态底账、Tier 1/2/3 参数分类证明 | 撰写毕业论文、同行评审专家 |
| [`docs/隐性规则与避坑指南.md`](docs/隐性规则与避坑指南.md) | 刚性求解器配置、代数环破环、PCHE 双区离散机理 | 新接手课题的学弟学妹、维护者 |
| [`docs/STATUS.md`](docs/STATUS.md) | 最新工作状态、已闭合结论、下一步探索计划 | 日常科研进度跟踪 |
| [`docs/DECISIONS.md`](docs/DECISIONS.md) | D01/D02/D03 决策记录，回热器与转速排查全过程 | 深入排查系统动力学机制 |
| [`docs/model_inventory.tsv`](docs/model_inventory.tsv) | 历史所有 SLX 模型的 SHA-256 清单及角色说明 | 防模型混淆与版本回溯 |
| [`sources/README.md`](sources/README.md) | 包含徐驰硕士论文、NASA报告在内的文献出处统一入口 | 溯源文献出处 |

---

## 🔬 系统 40 状态架构简述

模型由 40 个微分状态（连续积分器）完整描述：
- **中间热交换器 (IHX)**：10 状态（冷侧均温/出口、热侧均温/出口、管壁温度 $\times$ 2 区）
- **预冷器 (Precooler)**：10 状态（冷侧均温/出口、热侧均温/出口、管壁温度 $\times$ 2 区）
- **回热器 (Recuperator)**：10 状态（冷侧均温/出口、热侧均温/出口、管壁温度 $\times$ 2 区）
- **核反应堆堆芯 (Reactor)**：8 状态（6 组缓发中子先驱核浓度 $C_1 \dots C_6$ + 堆瞬时功率 $P_{Rx}$ + 燃料平均温度 $T_f$）
- **透平压气发电机组 (TAC)**：1 状态（发电机转子机械转速 $N_{rpm} = 55,090\text{ rpm}$）
- **空间辐射散热器 (Radiator)**：1 状态（辐射等效壁面温度 $T_{rad}$）

---

## 🛡️ 学术诚信与零造假承诺 (Zero Falsification Pledge)

1. **坚持实事求是**：对于未能 100% 与徐驰论文完全闭合的参数（如反应堆内部传热 $hA$ 与 $\gamma/\kappa$ 差额、辐射散热器两状态假设的数学秩亏），本仓库**全数公开、透明保留**在诊断文档中。
2. **严禁硬调参数**：绝不通过在模型中人为引入隐形控制器、常数补偿项或修改物理公式来强行伪造与文献曲线的“完美吻合”。
3. **不可变数据锁定**：`data/provenance/` 目录下所有历史基线通过 SHA-256 签名，接受全球科研同行监督复验。

---

## 📖 学术引用规范 (Citation)

如果您在学术论文、科研报告或毕业设计中参考或使用了本仓库的代码与诊断结论，请按如下格式予以引用：

```bibtex
@misc{he_xe_brayton_dynamic_model_2026,
  author = {Amadeus and JolnJack Contributors},
  title = {Space Lithium-Cooled Reactor He-Xe Brayton Cycle Dynamic Simulation & Verification Platform},
  year = {2026},
  publisher = {GitHub},
  howpublished = {\url{https://github.com/JolnJack/he-xe-brayton-dynamic-model}},
  note = {Reproducible benchmark with 361 automated verification gates}
}
```

参考的基础学位论文：
```text
徐驰. 空间锂冷堆He-Xe布雷顿循环发电系统优化设计与运行特性分析[D]. 合肥: 中国科学技术大学, 2022.
```
