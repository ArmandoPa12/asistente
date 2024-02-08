

import 'package:dialog_flowtter/dialog_flowtter.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

import 'package:flutter_tts/flutter_tts.dart';

//dialog
import 'package:dialogflow_flutter/dialogflowFlutter.dart';
import 'package:dialogflow_flutter/googleAuth.dart';
import 'package:dialogflow_flutter/language.dart';
import 'package:dialogflow_flutter/message.dart';

import 'package:animated_text_kit/animated_text_kit.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      //home: const Speech(),
      //home: const Textt(),
      home : DialogFlowScreen()
    );
  }
}


class DialogFlowScreen extends StatefulWidget {
  const DialogFlowScreen({super.key});

  @override
  State<DialogFlowScreen> createState() => _DialogFlowScreenState();
}

class _DialogFlowScreenState extends State<DialogFlowScreen> {
  final messageController = TextEditingController();
  List<Map> messages = [];

  late DialogFlowtter dialogFlowtter;
  List<Map<String,dynamic>> mensaje = [];
  String mensa = "---";

  @override
  void initState() {
    DialogFlowtter.fromFile().then((instance) => dialogFlowtter = instance);

    super.initState();
  }

  sendMessage(String text)async{
    DetectIntentResponse response = await dialogFlowtter.detectIntent(
        queryInput: QueryInput(text: TextInput(text: text)));

    String? textResponse = response.text;

    if (textResponse == null){
      print("nulo");
    }else{
      setState(() {
        mensa = textResponse;
        List<String> words = splitSentence(mensa);
        processWords(words);
        print("words------"+words.toString());
        print(response.message);
        mensaje.add({"message":mensa});
      });
      print(textResponse);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('chatBot'),
      ),

      body: Container(
        child: Column(
          children: [

            TextField(
              controller: messageController,
              style: TextStyle(
                color: Colors.black
              ),
            ),
            TextButton(
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all<Color>(Colors.blue),
              ),
              onPressed: () {
                if(messageController.text.isEmpty){
                  //print("mensaje vacio");
                }else{
                  setState(() {
                    messages.insert(0, {"data":1, "message":messageController.text });
                  });


                  //response(messageController.text);
                  sendMessage(messageController.text);
                  //messageController.clear();

                  //print(messages);
                }

              },
              child: Text('Enviar intent'),
            ),
            TextButton(
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all<Color>(Colors.blue),
              ),
              onPressed: () {
                    _test();
              },
              child: Text('prueb datos'),
            ),
            Text(mensa),
          ],
        ),
      ),
    );
  }
}

void _test(){
  List<String> words = splitSentence("A su pedido se le agrego un pollo agridulce, Desea alguna salsa?");
  processWords(words);
  //print("words------"+words.toString());
}


//auxiliares
List<String> splitSentence(String sentence) {
  List<String> words = sentence.split(' ');
  words.removeWhere((word) => word.isEmpty);
  print(words.toString());
  return words;
}

void processWords(List<String> words) {
  bool isPedido = false;
  bool isAgrego = false;
  bool isQuito = false;

  for (int i = 0; i < words.length; i++) {
    if (words[i].toLowerCase() == "pedido" || words[i].toLowerCase() == "pedido,") {
      isPedido = true;

      // Verificar si hay "agrego" o "quito" después de "pedido"
      for (int j = i + 1; j < words.length; j++) {
        if (words[j].toLowerCase() == "agrego") {
          isAgrego = true;
          break;
        } else if (words[j].toLowerCase() == "quito") {
          isQuito = true;
          break;
        }
      }

      // No necesitamos seguir buscando después de encontrar "pedido"
      break;
    }
  }

  if (isPedido) {
    if (isAgrego) {
      print("El pedido se está agregando.");
      // Llamar a la función correspondiente para agregar el pedido
    } else if (isQuito) {
      print("El pedido se está quitando.");
      // Llamar a la función correspondiente para quitar el pedido
    } else {
      print("El pedido no tiene acciones específicas.");
      // Lógica adicional si es necesario
    }
  } else {
    print("No se encontró la palabra 'pedido' en la lista.");
  }
}


//***************************************************

class Speech extends StatefulWidget {
  const Speech({super.key});

  @override
  State<Speech> createState() => _SpeechState();
}

class _SpeechState extends State<Speech> {
  //fluter
  ScrollController _controller = ScrollController();


  //instancia de librerias
  SpeechToText _speech = SpeechToText();
  final FlutterTts flutterTts = FlutterTts();

  //stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = 'Presionar para hablar';
  double _confidence = 1.0;

  //dialogflow
  late DialogFlowtter dialogFlowtter;
  List<Map<String,dynamic>> mensaje = [];


  @override
  void initState() {
    DialogFlowtter.fromFile().then((instance) => dialogFlowtter = instance);
    super.initState();
    //_speech = stt.SpeechToText();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(

        onStatus: (val) async{

          if (val == 'done'){
            DetectIntentResponse response = await dialogFlowtter.detectIntent(queryInput: QueryInput(text: TextInput(text: _text)));
            String? textResponse = response.text;
            textResponse == null ? textResponse="error de conexion" : mensaje.add({"message": textResponse});

            print("contr"+_controller.position.maxScrollExtent.toString());

            //listViewScrollController.animateTo(listViewScrollController.position.maxScrollExtent)
            /*if (textResponse == null){
              return;
            }else{
              mensaje.add({"message": textResponse});

            }*/
            flutterTts.setLanguage('es-ES');
            flutterTts.speak(textResponse);

            setState(() {
              _isListening = false;
              _controller.jumpTo(_controller.position.maxScrollExtent);
            });

            /*setState(() async{
              print("-----------user: " + _text);
              DetectIntentResponse response = await dialogFlowtter.detectIntent(queryInput: QueryInput(text: TextInput(text: _text)));
              String? textResponse = response.text;
              if (textResponse == null){
                return;
              }else{
                mensaje.add({"message": textResponse});
                //print(mensaje);
              }
                _text = "";
                _isListening = false;
                flutterTts.setLanguage('es-ES');
                flutterTts.speak(textResponse);
              }
            );*/

          }
          print('onStatus: $val');
        },
        //onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),

      );
      if (available) {
        //_localeNames = await _speech.locales();
        //print(_localeNames.toString());
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _text = val.recognizedWords;


            if (val.hasConfidenceRating && val.confidence > 0) {
              _confidence = val.confidence;
            }
          }),
          localeId: 'es-Es'
        );
      }
    } else {

      setState(() => _isListening = false);
      _speech.stop();
    }

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voz a audio'),
        //title: Text('Confidence: ${(_confidence * 100.0).toStringAsFixed(1)}%'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      floatingActionButton: FloatingActionButton(

        onPressed: _listen,
        //child: Icon(_isListening ? Icons.mic : Icons.mic_none),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(
              Radius.circular(10),
            ),
            color: _isListening? Colors.pink:Colors.transparent,
            boxShadow: [
              BoxShadow(
                color: _isListening? Colors.pink:Colors.transparent,
                spreadRadius: 10,
                blurRadius: 18,
                offset: Offset(0, 0),
              )
            ]
          ),
          child: Icon(_isListening ? Icons.mic : Icons.mic_none),
        ),
      ),

      body: Column(
        children: [
          Flexible(child: ListView.builder(
            shrinkWrap: true,
            //reverse: true,
            controller: _controller,
            itemCount: mensaje.length,
            itemBuilder: (BuildContext,index){
            return buble(mensaje[index]["message"].toString());

          },)),
          SizedBox(height: 90,)
        ],
      ),
      /**body: SingleChildScrollView(
        reverse: true,
        child: Container(
          padding: const EdgeInsets.fromLTRB(30.0, 30.0, 30.0, 150.0),
          child: Text("[$_text]")
        ),
      ),**/
    );
  }




  Widget buble(String sms){
    return Container(
      margin: EdgeInsets.only(left: 10,right: 10, top: 15) ,
      //color: Colors.white,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        border: Border.all(
          color: Colors.black,
          width: 1
        )
      ),
      child: Row(
        children: [
          Container(
            margin: EdgeInsets.only(left: 5,top: 5,bottom: 5),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage('assets/user.png'), // Ruta de tu imagen
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SizedBox(width: 15,),
          Flexible(child: Text(
            sms,
            style: TextStyle(
                fontSize: 15
            ),
          ))
        ],
      ),
    );
  }
}




//***************************************************

class Textt extends StatefulWidget {
  const Textt({super.key});

  @override
  State<Textt> createState() => _TexttState();
}

class _TexttState extends State<Textt> {
  final FlutterTts flutterTts = FlutterTts();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Text to speak'),),
      body: Center(
        child: Column(
          children: [
            Text('Hola, estamos probando flutter'),
            ElevatedButton(
              onPressed: (){
                //print(flutterTts.getVoices.toJS);

                flutterTts.setLanguage('es-ES');
                //flutterTts.setVoice('en-US-language');
                flutterTts.speak('Hola, estamos probando flutter');
              },
              child: Text('Speak'),
            ),
          ],
        ),
      ),
    );
  }
}

//***************************************************










