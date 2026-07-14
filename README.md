# 男友相机（Flutter）

参考原生 Android 项目 `kevingogo-code/BoyfriendCamera-trae-android` 重建的 Flutter 跨端第一版。实际开发与提交仓库仍为 `kevingogo-code/BoyfriendCamera`。

## 第一版功能

- 后置相机实时预览与手动拍照
- 两套自定义姿势轮廓（侧身撩发、正面撩发），可切换、拖动和缩放
- 姿势轮廓使用紧边裁切的透明 PNG；相机预览区只显示人物虚线，不显示原图棋盘格或矩形底框
- 本地 ML Kit 姿态检测、贴合度与人物位置提示
- 拍后预览、重拍及保存
- 自动保存到系统 `BoyfriendCamera` 相册
- 左下角最近照片缩略图
- 应用内照片网格和照片详情查看
- Android 与 iOS 共用 Flutter UI 和业务逻辑

姿态分析限制为约每 420ms 一次，避免逐帧 ML Kit 推理阻塞相机预览。

## 本地运行

```bash
/Users/didi/flutter/bin/flutter pub get
/Users/didi/flutter/bin/flutter run
```

Android 调试包：

```bash
/Users/didi/flutter/bin/flutter build apk --debug
```

## 平台要求

- Android 7.0（API 24）及以上
- iOS 15.5 及以上
