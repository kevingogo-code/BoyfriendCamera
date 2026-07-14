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
    required this.keypoints,
  });

  final String id;
  final String name;
  final String asset;
  final double centerX;
  final double centerY;
  final double heightRatio;
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
    id: 'street_1',
    name: '街拍姿势一',
    asset: 'assets/poses/pose_street_1.png',
    centerX: .5,
    centerY: .55,
    heightRatio: .7,
    keypoints: _pose(const [
      PosePoint(.58, .10),
      PosePoint(.68, .18),
      PosePoint(.46, .18),
      PosePoint(.72, .34),
      PosePoint(.30, .10),
      PosePoint(.68, .46),
      PosePoint(.10, .05),
      PosePoint(.62, .38),
      PosePoint(.48, .38),
      PosePoint(.64, .65),
      PosePoint(.50, .65),
      PosePoint(.62, .90),
      PosePoint(.52, .90),
    ]),
  ),
  PoseTemplate(
    id: 'street_2',
    name: '街拍姿势二',
    asset: 'assets/poses/pose_street_2.png',
    centerX: .65,
    centerY: .55,
    heightRatio: .72,
    keypoints: _pose(const [
      PosePoint(.50, .10),
      PosePoint(.62, .18),
      PosePoint(.38, .18),
      PosePoint(.70, .28),
      PosePoint(.30, .30),
      PosePoint(.75, .18),
      PosePoint(.25, .42),
      PosePoint(.58, .36),
      PosePoint(.42, .36),
      PosePoint(.62, .60),
      PosePoint(.42, .62),
      PosePoint(.65, .90),
      PosePoint(.40, .88),
    ]),
  ),
  PoseTemplate(
    id: 'street_3',
    name: '街拍姿势三',
    asset: 'assets/poses/pose_street_3.png',
    centerX: .35,
    centerY: .52,
    heightRatio: .68,
    keypoints: _pose(const [
      PosePoint(.52, .10),
      PosePoint(.64, .18),
      PosePoint(.40, .18),
      PosePoint(.70, .32),
      PosePoint(.34, .32),
      PosePoint(.72, .48),
      PosePoint(.32, .46),
      PosePoint(.60, .38),
      PosePoint(.44, .38),
      PosePoint(.56, .64),
      PosePoint(.50, .62),
      PosePoint(.54, .90),
      PosePoint(.52, .88),
    ]),
  ),
];
