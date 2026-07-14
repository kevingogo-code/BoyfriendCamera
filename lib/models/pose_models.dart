import 'dart:math' as math;

class PosePoint {
  const PosePoint(this.x, this.y, {this.z = 0, this.visibility = 1});

  final double x;
  final double y;
  final double z;
  final double visibility;
}

class PoseBounds {
  const PoseBounds({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });

  final double minX;
  final double maxX;
  final double minY;
  final double maxY;

  double get width => maxX - minX;
  double get height => maxY - minY;
  double get centerX => (minX + maxX) / 2;
}

class PoseKeypoints {
  const PoseKeypoints({
    required this.nose,
    required this.leftShoulder,
    required this.rightShoulder,
    required this.leftElbow,
    required this.rightElbow,
    required this.leftWrist,
    required this.rightWrist,
    required this.leftHip,
    required this.rightHip,
    required this.leftKnee,
    required this.rightKnee,
    required this.leftAnkle,
    required this.rightAnkle,
    required this.bounds,
  });

  final PosePoint nose;
  final PosePoint leftShoulder;
  final PosePoint rightShoulder;
  final PosePoint leftElbow;
  final PosePoint rightElbow;
  final PosePoint leftWrist;
  final PosePoint rightWrist;
  final PosePoint leftHip;
  final PosePoint rightHip;
  final PosePoint leftKnee;
  final PosePoint rightKnee;
  final PosePoint leftAnkle;
  final PosePoint rightAnkle;
  final PoseBounds bounds;

  PosePoint get shoulderMid => PosePoint(
    (leftShoulder.x + rightShoulder.x) / 2,
    (leftShoulder.y + rightShoulder.y) / 2,
  );

  PosePoint get hipMid =>
      PosePoint((leftHip.x + rightHip.x) / 2, (leftHip.y + rightHip.y) / 2);

  double get shoulderWidth => math.sqrt(
    math.pow(leftShoulder.x - rightShoulder.x, 2) +
        math.pow(leftShoulder.y - rightShoulder.y, 2),
  );

  List<PosePoint> get allPoints => [
    nose,
    leftShoulder,
    rightShoulder,
    leftElbow,
    rightElbow,
    leftWrist,
    rightWrist,
    leftHip,
    rightHip,
    leftKnee,
    rightKnee,
    leftAnkle,
    rightAnkle,
  ];
}

class PoseTemplate {
  const PoseTemplate({
    required this.id,
    required this.name,
    required this.asset,
    required this.centerX,
    required this.centerY,
    required this.heightRatio,
    required this.aspectRatio,
    required this.keypoints,
  });

  final String id;
  final String name;
  final String asset;
  final double centerX;
  final double centerY;
  final double heightRatio;
  final double aspectRatio;
  final PoseKeypoints keypoints;
}

PoseKeypoints _pose(List<PosePoint> points) {
  final minX = points.map((point) => point.x).reduce(math.min);
  final maxX = points.map((point) => point.x).reduce(math.max);
  final minY = points.map((point) => point.y).reduce(math.min);
  final maxY = points.map((point) => point.y).reduce(math.max);
  return PoseKeypoints(
    nose: points[0],
    leftShoulder: points[1],
    rightShoulder: points[2],
    leftElbow: points[3],
    rightElbow: points[4],
    leftWrist: points[5],
    rightWrist: points[6],
    leftHip: points[7],
    rightHip: points[8],
    leftKnee: points[9],
    rightKnee: points[10],
    leftAnkle: points[11],
    rightAnkle: points[12],
    bounds: PoseBounds(minX: minX, maxX: maxX, minY: minY, maxY: maxY),
  );
}

final poseTemplates = <PoseTemplate>[
  PoseTemplate(
    id: 'side_hair_touch',
    name: '侧身撩发',
    asset: 'assets/poses/pose_template_1.png',
    centerX: .5,
    centerY: .53,
    heightRatio: .78,
    aspectRatio: .477,
    keypoints: _pose(const [
      PosePoint(.47, .20),
      PosePoint(.25, .30),
      PosePoint(.55, .26),
      PosePoint(.27, .47),
      PosePoint(.67, .25),
      PosePoint(.38, .64),
      PosePoint(.66, .30),
      PosePoint(.36, .54),
      PosePoint(.61, .54),
      PosePoint(.47, .78),
      PosePoint(.72, .79),
      PosePoint(.48, .97),
      PosePoint(.84, .97),
    ]),
  ),
  PoseTemplate(
    id: 'front_hair_touch',
    name: '正面撩发',
    asset: 'assets/poses/pose_template_2.png',
    centerX: .5,
    centerY: .52,
    heightRatio: .80,
    aspectRatio: .493,
    keypoints: _pose(const [
      PosePoint(.57, .11),
      PosePoint(.45, .23),
      PosePoint(.67, .22),
      PosePoint(.31, .15),
      PosePoint(.75, .40),
      PosePoint(.48, .09),
      PosePoint(.74, .66),
      PosePoint(.50, .50),
      PosePoint(.66, .50),
      PosePoint(.48, .76),
      PosePoint(.66, .76),
      PosePoint(.48, .98),
      PosePoint(.66, .98),
    ]),
  ),
];
