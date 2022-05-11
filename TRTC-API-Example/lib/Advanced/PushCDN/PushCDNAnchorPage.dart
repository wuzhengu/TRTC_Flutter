import 'package:flutter/material.dart';
import 'package:tencent_trtc_cloud/trtc_cloud.dart';
import 'package:tencent_trtc_cloud/trtc_cloud_def.dart';
import 'package:tencent_trtc_cloud/trtc_cloud_listener.dart';
import 'package:tencent_trtc_cloud/trtc_cloud_video_view.dart';
import 'package:trtc_api_example/Common/TXHelper.dart';
import 'package:trtc_api_example/Common/TXUpdateEvent.dart';
import 'package:trtc_api_example/Debug/GenerateTestUserSig.dart';

///  SetBGMPage.dart
///  TRTC-API-Example-Dart
class PushCDNAnchorPage extends StatefulWidget {
  const PushCDNAnchorPage({Key? key}) : super(key: key);

  @override
  _PushCDNAnchorPageState createState() => _PushCDNAnchorPageState();
}

class _PushCDNAnchorPageState extends State<PushCDNAnchorPage> {
  late TRTCCloud trtcCloud;
  String currentMixConfig = 'picture';
  int? localViewId;
  bool isStartPush = false;
  int roomId = int.parse(TXHelper.generateRandomStrRoomId());
  String userId = TXHelper.generateRandomUserId();
  List<String> remoteUidList = [];
  Map<String, TRTCRenderParams> remoteRenderParamsDic = {};
 
  @override
  void initState() {
    initTRTCCloud();
    super.initState();
    eventBus.fire(TitleUpdateEvent('房间号: $roomId'));
  }

  initTRTCCloud() async {
    trtcCloud = (await TRTCCloud.sharedInstance())!;
    trtcCloud.registerListener(onTrtcListener);
  }

  startPushStream() async {
    trtcCloud.startLocalPreview(true, localViewId);
    TRTCParams params = new TRTCParams();
    params.sdkAppId = GenerateTestUserSig.sdkAppId;
    params.roomId = this.roomId;
    params.userId = this.userId;
    params.role = TRTCCloudDef.TRTCRoleAnchor;
    params.userSig = await GenerateTestUserSig.genTestSig(params.userId);
    params.streamId = getStreamId();
    trtcCloud.callExperimentalAPI(
        "{\"api\": \"setFramework\", \"params\": {\"framework\": 7, \"component\": 2}}");
    trtcCloud.enterRoom(params, TRTCCloudDef.TRTC_APP_SCENE_LIVE);

    TRTCVideoEncParam encParams = new TRTCVideoEncParam();
    encParams.videoResolution = TRTCCloudDef.TRTC_VIDEO_RESOLUTION_960_540;
    // TRTCVideoResolution 中仅定义了横屏分辨率（如 640 × 360），如需使用竖屏分辨率（如360 × 640），需要同时指定 TRTCVideoResolutionMode 为 Portrait。
    encParams.videoResolutionMode = 1;
    encParams.videoFps = 24;
    trtcCloud.setVideoEncoderParam(encParams);
    trtcCloud.startLocalAudio(TRTCCloudDef.TRTC_AUDIO_QUALITY_MUSIC);
  }

  onTrtcListener(type, params) async {
    switch (type) {
      case TRTCCloudListener.onError:
        break;
      case TRTCCloudListener.onWarning:
        break;
      case TRTCCloudListener.onEnterRoom:
        break;
      case TRTCCloudListener.onExitRoom:
        break;
      case TRTCCloudListener.onSwitchRoom:
        break;
      case TRTCCloudListener.onUserVideoAvailable:
        print("==test onUserVideoAvailable" + params['available'].toString());
        onUserVideoAvailable(params["userId"], params['available']);
        break;
      case TRTCCloudListener.onUserSubStreamAvailable:
        break;
      case TRTCCloudListener.onStartPublishing:
        print("==test onStartPublishing" + params['errCode'].toString());
        break;
      case TRTCCloudListener.onStopPublishing:
        break;
      case TRTCCloudListener.onSetMixTranscodingConfig:
        print("==test onSetMixTranscodingConfig" + params['errCode'].toString());
        break;
    }
  }

  onUserVideoAvailable(String userId, bool available) {
    if (available) {
        remoteUidList.add(userId);
    } else {
        remoteUidList.remove(userId);
    }

    if(remoteUidList.length > 0) {
      setMixConfig(currentMixConfig);
    } else {
      trtcCloud.setMixTranscodingConfig(null);
    }
    setState(() {});
  }

  destroyRoom() async {
    trtcCloud.stopLocalPreview();
    trtcCloud.exitRoom();
    trtcCloud.unRegisterListener(onTrtcListener);
    await TRTCCloud.destroySharedInstance();
  }

  @override
  dispose() {
    destroyRoom();
    super.dispose();
  }

    // 设置全手动排版模式
    // 具体使用方式见<a href="https://cloud.tencent.com/document/product/647/16827">云端混流转码</a>
    setMixConfigManual() {
        TRTCTranscodingConfig config = new TRTCTranscodingConfig();
        config.videoWidth      = 720;
        config.videoHeight     = 1280;
        config.videoBitrate    = 1500;
        config.videoFramerate  = 20;
        config.videoGOP        = 2;
        config.audioSampleRate = 48000;
        config.audioBitrate    = 64;
        config.audioChannels   = 2;
        config.streamId        = getStreamId();
        config.appId           = GenerateTestUserSig.appId;
        config.bizId           = GenerateTestUserSig.bizId;
        config.backgroundColor = 0x000000;
        config.backgroundImage = null;

        config.mode = TRTCCloudDef.TRTC_TranscodingConfigMode_Manual;
        config.mixUsers = [];

        //  主播自己
        TRTCMixUser mixUser = new TRTCMixUser();
        mixUser.userId = this.userId;
        mixUser.zOrder = 0;
        mixUser.x = 0;
        mixUser.y = 0;
        mixUser.width = 720;
        mixUser.height = 1280;
        mixUser.roomId = this.roomId.toString();
        config.mixUsers?.add(mixUser);

        for(int i = 0; i < remoteUidList.length && i < 3; i++){
            TRTCMixUser remote = TRTCMixUser();
            remote.userId = remoteUidList[i];
            remote.streamType = TRTCCloudDef.TRTC_VIDEO_STREAM_TYPE_BIG;
            remote.zOrder = 1;
            remote.x      = 180 + i * 20;
            remote.y      = 400 + i * 20;
            remote.width  = 135;
            remote.height = 240;
            remote.roomId = this.roomId.toString();
            config.mixUsers!.add(remote);
        }
        trtcCloud.setMixTranscodingConfig(config);
    }

    /// 设置混流预排版-左右模式
    /// 具体使用方式见<a href="https://cloud.tencent.com/document/product/647/16827">云端混流转码</a>
    setMixConfigLeftRight() {
        TRTCTranscodingConfig config = TRTCTranscodingConfig();
        config.videoWidth      = 720;
        config.videoHeight     = 640;
        config.videoBitrate    = 1500;
        config.videoFramerate  = 20;
        config.videoGOP        = 2;
        config.audioSampleRate = 48000;
        config.audioBitrate    = 64;
        config.audioChannels   = 2;

        
        config.streamId  = getStreamId();

        config.mode = TRTCCloudDef.TRTC_TranscodingConfigMode_Template_PresetLayout;
        config.mixUsers = [];

        //       主播自己
        TRTCMixUser mixUser = TRTCMixUser();
        mixUser.userId = "\$PLACE_HOLDER_LOCAL_MAIN\$";
        mixUser.zOrder = 0;
        mixUser.x = 0;
        mixUser.y = 0;
        mixUser.width = 360;
        mixUser.height = 640;
        mixUser.roomId = this.roomId.toString();
        config.mixUsers?.add(mixUser);


        //连麦者画面位置
        TRTCMixUser remote = TRTCMixUser();
        remote.userId = "\$PLACE_HOLDER_REMOTE\$";
        remote.streamType = TRTCCloudDef.TRTC_VIDEO_STREAM_TYPE_BIG;
        remote.zOrder = 1;
        remote.x      = 360;
        remote.y      = 0;
        remote.width  = 360;
        remote.height = 640;
        remote.roomId = this.roomId.toString();
        config.mixUsers?.add(remote);

        trtcCloud.setMixTranscodingConfig(config);
    }

    String getStreamId() {
      String streamId = GenerateTestUserSig.sdkAppId.toString() +
          '_' +
          this.roomId.toString() +
          '_' +
          this.userId +
          '_main';
      return streamId;
    }

    /// 预排版-画中画
    /// 具体使用方式见<a href="https://cloud.tencent.com/document/product/647/16827">云端混流转码</a>
    setMixConfigInPicture() {
        TRTCTranscodingConfig config = TRTCTranscodingConfig();
        config.videoWidth      = 720;
        config.videoHeight     = 1280;
        config.videoBitrate    = 1500;
        config.videoFramerate  = 20;
        config.videoGOP        = 2;
        config.audioSampleRate = 48000;
        config.audioBitrate    = 64;
        config.audioChannels   = 2;
        config.streamId        = getStreamId();

        config.mode = TRTCCloudDef.TRTC_TranscodingConfigMode_Template_PresetLayout;
        config.mixUsers = [];

        // 主播自己
        TRTCMixUser mixUser = TRTCMixUser();
        mixUser.userId = "\$PLACE_HOLDER_LOCAL_MAIN\$";
        mixUser.zOrder = 0;
        mixUser.x = 0;
        mixUser.y = 0;
        mixUser.width = 720;
        mixUser.height = 1280;
        mixUser.roomId = this.roomId.toString();
        config.mixUsers?.add(mixUser);


        //连麦者画面位置
        TRTCMixUser remote = TRTCMixUser();
        remote.userId = "\$PLACE_HOLDER_REMOTE\$";
        remote.streamType = TRTCCloudDef.TRTC_VIDEO_STREAM_TYPE_BIG;

        remote.zOrder = 1;
        remote.x      = 500;
        remote.y      = 150;
        remote.width  = 135;
        remote.height = 240;
        remote.roomId = this.roomId.toString();
        config.mixUsers?.add(remote);

        trtcCloud.setMixTranscodingConfig(config);
    }

  Widget getButtonItem({
    required String tile,
    required String value,
    required Function onClick,
  }) {
    MaterialStateProperty<Color> greenColor = currentMixConfig == value ?
        MaterialStateProperty.all(Colors.green) : MaterialStateProperty.all(Colors.grey); 

    return ElevatedButton(
      style: ButtonStyle(
        textStyle: MaterialStateProperty.all(
          TextStyle(fontSize: 12),
        ),
        padding: MaterialStateProperty.all(
          EdgeInsets.only(left: 0, right: 0),
        ),
        backgroundColor: greenColor,
      ),
      onPressed: () {
        onClick(value);
      },
      child: Text(tile),
    );
  }

  setMixConfig(value) {
    print("== setmix");
    setState(() {
      currentMixConfig = value;
    });
    if(value == 'manual') {
      setMixConfigManual();
    } else if(value == 'leftRight') {
      setMixConfigLeftRight();
    } else if(value == 'picture') {
      setMixConfigInPicture();
    }
  }

  getBGWidgetList() {
    return [
      getButtonItem(
        tile: "全手动模式",
        value: "manual",
        onClick: setMixConfig,
      ),
      SizedBox(
        width: 20,
      ),
      getButtonItem(
        tile: "预排版左右",
        value: "leftRight",
        onClick: setMixConfig,
      ),
      SizedBox(
        width: 20,
      ),
      getButtonItem(
        tile: "预排版画中画",
        value: "picture",
        onClick: setMixConfig,
      ),
    ];
  }

  onPushStreamClick() {
    bool newIsStartPush = !isStartPush;
    isStartPush = newIsStartPush;
    if (isStartPush) {
      startPushStream();
    } else {
      remoteRenderParamsDic.clear();
      remoteUidList = [];
      trtcCloud.unRegisterListener(onTrtcListener);
      trtcCloud.stopLocalAudio();
      trtcCloud.stopLocalPreview();
      trtcCloud.exitRoom();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topLeft,
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {},
          child: TRTCCloudVideoView(
            key: ValueKey("LocalView"),
            viewType: TRTCCloudDef.TRTC_VideoView_TextureView,
            onViewCreated: (viewId) async {
              setState(() {
                localViewId = viewId;
              });
            },
          ),
        ),
        Positioned(
          left: 10,
          top: 15,
          width: 72,
          height: 370,
          child: Container(
            child: GridView.builder(
              itemCount: remoteUidList.length,
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                childAspectRatio: 0.6,
              ),
              itemBuilder: (BuildContext context, int index) {
                String userId = remoteUidList[index];
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 72,
                    minWidth: 72,
                    maxHeight: 120,
                    minHeight: 120,
                  ),
                  child: Stack(
                    children: [
                      TRTCCloudVideoView(
                          key: ValueKey('RemoteView_$userId'),
                          viewType: TRTCCloudDef.TRTC_VideoView_TextureView,
                          onViewCreated: (viewId) async {
                            trtcCloud.startRemoteView(
                                userId,
                                TRTCCloudDef.TRTC_VIDEO_STREAM_TYPE_BIG,
                                viewId);
                          },
                        ),
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Text(
                          userId,
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          left: 0,
          height: 190,
          bottom: 15,
          child: Container(
            padding: EdgeInsets.only(left: 15, right: 15),
            width: MediaQuery.of(context).size.width,
            height: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                Row(
                  children: [
                    Text('多路云端混流(主播数>=2)'),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: getBGWidgetList(),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: 100,
                      child: TextField(
                        autofocus: false,
                        enabled: !isStartPush,
                        decoration: InputDecoration(
                          labelStyle: TextStyle(color: Colors.white),
                          labelText: "房间号",
                        ),
                        controller: TextEditingController.fromValue(
                          TextEditingValue(
                            text: this.roomId.toString(),
                            selection: TextSelection.fromPosition(
                              TextPosition(
                                affinity: TextAffinity.downstream,
                                offset: this.roomId.toString().length,
                              ),
                            ),
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          roomId = int.parse(value);
                          eventBus.fire(TitleUpdateEvent('房间号: $roomId'));
                        },
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: TextField(
                        autofocus: false,
                        enabled: !isStartPush,
                        decoration: InputDecoration(
                          labelText: "user ID",
                          labelStyle: TextStyle(color: Colors.white),
                        ),
                        controller: TextEditingController.fromValue(
                          TextEditingValue(
                            text: this.userId,
                            selection: TextSelection.fromPosition(
                              TextPosition(
                                affinity: TextAffinity.downstream,
                                offset: this.userId.length,
                              ),
                            ),
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                        keyboardType: TextInputType.text,
                        onChanged: (value) {
                          userId = value;
                        },
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.green),
                        ),
                        onPressed: () {
                          onPushStreamClick();
                        },
                        child: Text(isStartPush ? '停止推流' : '开始推流'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
