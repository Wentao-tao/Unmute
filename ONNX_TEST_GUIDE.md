# ONNX 模型测试指南

## ✅ 已完成的配置

### 1. ONNX 模型验证
- ✅ Python 测试显示：ONNX 模型与 PyTorch 模型**完全一致**（差异 0.000000）
- ✅ 模型文件：`ecapa_tdnn_embedding.onnx`
- ✅ 输入名：`fbank`
- ✅ 输出名：`embedding`
- ✅ 输入格式：`[batch=1, features=80, time=动态]`

### 2. iOS 代码更新
- ✅ `Fbank80Extractor.swift`：已启用均值方差归一化（和 SpeechBrain 一致）
- ✅ `ONNXEmbeddingExtractor.swift`：已修正输入名为 `"fbank"`
- ✅ `VoiceService.swift`：已使用 ONNX Runtime
- ✅ `Podfile`：已添加 `onnxruntime-objc` 依赖

---

## 🧪 测试步骤

### 步骤 1：在 Xcode 中构建项目

1. 打开 `unmute.xcworkspace`（不是 .xcodeproj！）
2. 确保 `ecapa_tdnn_embedding.onnx` 文件已添加到项目中
3. 选择真机或模拟器
4. 点击 `Product` → `Build` (⌘B)

**预期结果：**
- 构建成功
- 看到控制台输出：`✅ ONNX Runtime 初始化成功`

---

### 步骤 2：运行 VoiceTestView 测试

1. 在 App 中找到"声纹测试"入口
2. 按照以下步骤测试：

#### 测试场景 1：同一个人（预期：高相似度 > 0.90）

```
1. 点击 "录制 Person A" → 说话 5+ 秒 → 停止
2. 等待 2 秒（提取特征）
3. 点击 "录制 Person A" → 再说话 5+ 秒 → 停止
4. 等待 2 秒（提取特征）
5. 点击 "计算相似度"
```

**预期结果：**
- 相似度：**0.90 - 0.99**
- 状态：⚠️ "相似度过高，可能是同一个人"

---

#### 测试场景 2：不同的人（预期：低相似度 < 0.60）

```
1. 点击 "录制 Person A" → 人 A 说话 5+ 秒 → 停止
2. 等待 2 秒
3. 点击 "录制 Person B" → 人 B 说话 5+ 秒 → 停止
4. 等待 2 秒
5. 点击 "计算相似度"
```

**预期结果：**
- 相似度：**0.01 - 0.50**（取决于两人声音差异）
- 状态：✅ "差异明显，模型可以区分"

---

### 步骤 3：检查详细日志

在测试界面的"详细日志"中查看：

```
📊 提取声纹特征...
   录音时长: 6.5秒
   提取范围: 500-5000ms (~4.5秒)

📊 Fbank 特征: 80 mels × 450 frames (~4.5秒)
✅ ONNX 推理成功
   Embedding 维度: 192
   原始 L2 范数: 25.231
   归一化后范数: 1.000

✅ Person A 声纹提取成功
   维度: 192
   前10维: 0.023, -0.015, 0.041, ...
   L2范数: 1.000

🔍 计算相似度...
   Person A vs Person B: 0.0234

✅ 结果：差异明显

📈 详细分析：
   欧氏距离: 1.423
   平均维度差异: 0.154
   最大维度差异: 0.312
```

---

## 📊 正确结果参考

### ECAPA-TDNN 模型的相似度标准：

| 场景 | 相似度范围 | 判断 |
|------|-----------|------|
| 同一人 | 0.85 - 0.99 | ✅ 正确识别 |
| 相似声音 | 0.70 - 0.85 | 🤔 需要更多样本 |
| 不同人 | 0.01 - 0.60 | ✅ 可以区分 |

---

## ⚠️ 常见问题

### 问题 1：所有人的相似度都很高（> 0.90）
**可能原因：**
- ❌ Fbank 归一化没有生效
- ❌ ONNX 模型输入名错误

**解决方案：**
- 检查 `Fbank80Extractor.swift` 第 123-143 行是否已取消注释
- 检查 `ONNXEmbeddingExtractor.swift` 第 102 行输入名是否为 `"fbank"`

---

### 问题 2：ONNX Runtime 初始化失败
**可能原因：**
- ❌ 没有运行 `pod install`
- ❌ 打开了 `.xcodeproj` 而不是 `.xcworkspace`
- ❌ ONNX 文件没有添加到项目

**解决方案：**
```bash
cd "/Users/wentao/Projects/Apple academy/Challenge 6/unmute"
pod install
open unmute.xcworkspace
```

---

### 问题 3：找不到 ONNX 模型文件
**错误信息：**
```
❌ 找不到 ONNX 模型文件: ecapa_tdnn_embedding.onnx
```

**解决方案：**
1. 在 Xcode 中，将 `ecapa_tdnn_embedding.onnx` 拖到 `Utility` 文件夹
2. 确保勾选 "Copy items if needed"
3. 确保勾选 "Add to targets: unmute"
4. 重新构建

---

### 问题 4：Embedding 维度不对
**预期维度：** 192

**如果不是 192：**
- 检查 ONNX 模型是否正确导出
- 确保使用的是 `ecapa_tdnn_embedding.onnx`（不是其他模型）

---

## 🎯 测试通过标准

✅ **合格标准：**
1. 同一个人的相似度：**> 0.85**
2. 不同人的相似度：**< 0.60**
3. Embedding 维度：**192**
4. L2 范数：**1.000** (归一化后)

✅ **理想标准：**
1. 同一个人的相似度：**> 0.90**
2. 不同人的相似度：**< 0.40**
3. 特征提取时间：**< 1 秒** (5 秒音频)

---

## 📝 测试记录模板

```
测试日期：2025-10-30
设备：[iPhone/模拟器]
iOS 版本：[15.0+]

场景 1：同一个人
- Person A 录音 1：6.2 秒
- Person A 录音 2：5.8 秒
- 相似度：0.954
- 结果：✅ 通过

场景 2：不同的人
- Person A：6.5 秒
- Person B：7.1 秒
- 相似度：0.023
- 结果：✅ 通过

总结：
✅ 模型工作正常
✅ 可以准确区分不同说话人
✅ 可以准备集成到主应用
```

---

## 🚀 下一步

测试通过后，你可以：
1. 在 `OnlineViewModel.swift` 中启用实时说话人识别
2. 调整识别阈值（建议从 0.80 开始）
3. 添加更多测试用例（3人、4人对话）
4. 优化性能（如果需要）

---

## 💡 性能优化建议

如果 ONNX 推理太慢：
1. 使用 Core ML 加速：`providers=['CoreMLExecutionProvider']`
2. 减少线程数：`setIntraOpNumThreads(1)`
3. 量化模型（可选）

如果内存占用太高：
1. 限制音频缓冲时长（当前 60 秒）
2. 及时清理不用的 embedding

---

祝测试顺利！🎉

