import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';

class Home extends StatefulWidget {
  const Home({Key? key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  CameraImage? cameraImage;
  CameraController? cameraController;
  String output = '';
  late List<CameraDescription> cameras;
  int selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    loadCameras();
    loadModel();
  }

  loadCameras() async {
    cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      setState(() {
        cameraController =
            CameraController(cameras[selectedCameraIndex], ResolutionPreset.medium);
        cameraController!.initialize().then((value) {
         if(!mounted){
        return;
      }else{
        setState(() {
          cameraController!.startImageStream((imageStream) { 
            cameraImage=imageStream;
            runModel();
          });
        });
      }
        });
      });
    }
  }

  toggleCamera() {
    setState(() {
      selectedCameraIndex = (selectedCameraIndex+1) % cameras.length;
      cameraController = CameraController(cameras[selectedCameraIndex], ResolutionPreset.medium);
      cameraController!.initialize().then((_) {
       if(!mounted){
        return;
      }else{
        setState(() {
          cameraController!.startImageStream((imageStream) { 
            cameraImage=imageStream;
            runModel();
          });
        });
      }
      });
    });
  }
 loadModel()async{
    await Tflite.loadModel(model:'assets/converted_tflite/model_unquant.tflite',
    labels:'assets/converted_tflite/labels.txt');
    
  }
  runModel()async{
    if(cameraImage!=null){
      var prediction=await Tflite.runModelOnFrame(bytesList:cameraImage!.planes.map((plane){
        return plane.bytes;
      }).toList(),
      imageHeight:cameraImage!.height,
      imageWidth:cameraImage!.width,
      imageMean:127.5,
      imageStd:127.5,
      rotation:90,
      numResults:2,
      threshold:0.1,
      asynch:true
      );
      prediction!.forEach((element) {
        setState(() {
          output=element['label'];
        });
      });
    }
  }
  // Other methods remain unchanged...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ml Project"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              width: MediaQuery.of(context).size.width,
              child: cameraController != null && cameraController!.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: cameraController!.value.aspectRatio,
                      child: CameraPreview(cameraController!),
                    )
                  : Container(),
            ),
          ),
          Text(
            output,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          ElevatedButton(
            onPressed: toggleCamera,
            child: Icon(Icons.flip_camera_ios),
          ),
        ],
      ),
    );
  }
}
