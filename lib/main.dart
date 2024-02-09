

import 'dart:async';

import 'package:dialog_flowtter/dialog_flowtter.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

import 'package:flutter_tts/flutter_tts.dart';
import 'pedido.dart';
//dialog
import 'package:dialogflow_flutter/dialogflowFlutter.dart';
import 'package:dialogflow_flutter/googleAuth.dart';
import 'package:dialogflow_flutter/language.dart';
import 'package:dialogflow_flutter/message.dart';

import 'package:animated_text_kit/animated_text_kit.dart';



void main() {
  runApp(const MyApp());
}

int error = 0;
int mainError = 0;
bool ayuda = false;

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
      home: const Speech(),
      //home: const Textt(),
      //home : DialogFlowScreen()
    );
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

  List<Map<String,String>> _total = [];

  Map<String,String> _pedido = {
    "pollo":"",
    "presa":"",
    "salsa":"",
    "cantidad":""};
  late Map<String, String> objeto;


  //instancia de librerias
  SpeechToText _speech = SpeechToText();


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
            if (textResponse == null){ textResponse="error de conexion";}


            //parametros
            if (textResponse.length > 0){
              logic(response.props[1].toString(), textResponse);
            }


            //print(_pedido);

            setState(() {
              _isListening = false;
              _controller.jumpTo(_controller.position.maxScrollExtent);
            });


          }
        },
        onError: (val) => print('onError: $val'),

      );
      if (available) {
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


  void logic(String texto, String respuesta)async{

    String cadObj = extraerObjetoEntreLlaves(texto);
    objeto = convertirCadenaAObjeto(cadObj);
    //parametros
    if(objeto.isNotEmpty){
      if (objeto["tipoPollo"]?.isNotEmpty ?? false){
        print(objeto["tipoPollo"]);
        _pedido["pollo"] = objeto["tipoPollo"]!;
      }
      if (objeto["cantidad"]?.isNotEmpty ?? false){
        print(objeto["cantidad"]);
        _pedido["cantidad"] = objeto["cantidad"]!;

      }
      if (objeto["tipoPresa"]?.isNotEmpty ?? false){
        print(objeto["tipoPresa"]);
        _pedido["presa"] = objeto["tipoPresa"]!;

      }
      if (objeto["tipoSalsa"]?.isNotEmpty ?? false){
        print(objeto["tipoSalsa"]);
        _pedido["salsa"] = objeto["tipoSalsa"]!;

      }


      /*if (objeto["tipoPago"]?.isNotEmpty ?? false){
        print(objeto["tipoPago"]);
        _pedido["pago"] = objeto["tipoPago"]!;

      }*/
    }



    if (respuesta.toLowerCase().contains("ups")){
      error = error+1;
    }

    print(" mi voz $_text");
    print('------------- $respuesta');
    print('---- todoValor? ${todosTienenValor(_pedido)}');

    if(error == 2){
      ayuda=true;
    }else{
      if (respuesta.toLowerCase().contains("nuevo")) {
        _total.add(_pedido);
        _pedido = {"pollo": ""};
        String x = "claro, que pollo le agrego a su pedido?";
        hablar(x);
        mensaje.add({"message": x});
      }else if(respuesta.toLowerCase().contains("usted")){
        int e = obtenerError(_pedido);
        if(e == -1){
          _total.add(_pedido);
          _pedido = {"pollo": ""};
          String pedidoFinal = resumen(_total);
          String x = "aqui esta su resumen";
          hablar(pedidoFinal);
          mensaje.add({"message": pedidoFinal});
        }else{
          errorHandler(e);
        }

      }else {
        if(respuesta.toLowerCase().contains("agrego")){
          print("-------agrego $_total");
          int p = obtenerError(_pedido);
          print("-------agrego $p");


          if (p == -1){
            respuesta = respuesta + "\nDesea agregar otro pollo a su pedido?";
          }else {
            String add = faltantePedido(p);
            respuesta = respuesta + "\n $add";
          }
          hablar(respuesta);
          mensaje.add({"message": respuesta});
        }else {
          hablar(respuesta);
          mensaje.add({"message": respuesta});
        }
      }
    }




    if (ayuda){
      error = 0;
      ayuda = !ayuda;
      int tipoError = obtenerError(_pedido);
      errorHandler(tipoError);
    }



  }

  int obtenerError(Map<String,String> __pedido){

    print("error: -----$__pedido");
    if(__pedido["pollo"]?.isEmpty ?? false){
      return 0;
    }else if(__pedido["cantidad"]?.isEmpty ?? false) {
      return 1;
    }else if(__pedido["presa"]?.isEmpty ?? false) {
      return 2;
    }else if(__pedido["salsa"]?.isEmpty ?? false){
      return 3;
    }else{
      return -1;
    }
  }

  void errorHandler(int e){
    if (e == 0){
      String x = "Aun no escogió el tipo de pollo que desea?";
      hablar(x);
      mensaje.add({"message": x});
    }else if(e==1){
      String x =("Aun le falta la cantidad de pollo que desea comer");
      hablar(x);
      mensaje.add({"message": x});
    }else if(e==2){
      String x =("Aun le falta escoger la, que presa desea comer hoy?");
      hablar(x);
      mensaje.add({"message": x});
    }else if(e==3){
      String x = ("Aun le falta escoger la salsa");
      hablar(x);
      mensaje.add({"message": x});
    }else if(e==4){
      String x =("Debe escoger un metodo de pago");
      hablar(x);
      mensaje.add({"message": x});
    }else{
      String x = ("su orden esta completa, desea agregar otra orden?");
      hablar(x);
      mensaje.add({"message": x});
    }

  }

  String faltantePedido(int e){
    if (e == 0){
      return "Que tipo de pollo desea?";
    }else if(e==1){
      return "Me confirma la cantidad por favor?";
    }else if(e==2){
      return "puede escoger la presa por favor";
    }else if(e==3){
      return "Cual de nuestras salsas desea?";
    }
    return "";
  }

  void hablar(String x)async{
    final FlutterTts flutterTts = FlutterTts();
    flutterTts.setLanguage('es-ES');
    flutterTts.speak(x);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voz a audio'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      floatingActionButton: FloatingActionButton(
        onPressed: _listen,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(
              Radius.circular(10),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.transparent,
                spreadRadius: 10,
                blurRadius: 18,
                offset: Offset(0, 0),
              )
            ]
          ),
          child: Icon(_isListening ?Icons.mic_none:Icons.mic_off_outlined),
        ),
      ),

      body: Column(
        children: [
          Container(
            height: 180,
            child: Card(
              elevation: 4,
              child: pedidoCard(_pedido["pollo"]?? "",_pedido["cantidad"]?? "",_pedido["presa"]?? "",_pedido["salsa"]?? "" )
            ),
          ),
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
          Flexible(child: Container(
            margin: EdgeInsets.only(right: 10, top: 10, bottom: 10),
            child: Text(
              sms,
              style: TextStyle(
                  fontSize: 15
              ),
            ),
          ))
        ],
      ),
    );
  }

  Widget pedidoCard(String _pollo, String _cantidad, String _presa, String _salsa){
    print(_cantidad);
    _pollo = capitalizarPrimeraLetra(_pollo);
    _presa = capitalizarPrimeraLetra(_presa);
    _salsa = capitalizarPrimeraLetra(_salsa);


    bool pollo = _pollo=="";
    bool cant = _cantidad=="";
    bool presa = _presa=="";
    bool salsa = _salsa=="";


    return Row(
      children: [
        Container(
          margin: EdgeInsets.only(top: 10,bottom: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.only(
                topRight: Radius.circular(10.0),
                bottomRight: Radius.circular(10.0)
            ),
            child: Image.asset(
               _pedido["pollo"]==""? 'assets/none.png':'assets/${_pedido["pollo"]}.png' ,
              fit: BoxFit.cover,
              width: 170,
              height: 170,
            ),

          ),
        ),
        Container(
          margin: EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                pollo ?'TipoPollo':_pollo,
                style: TextStyle(
                    fontSize: 18,
                    color: pollo?Colors.grey:Colors.black,
                    fontWeight: FontWeight.bold
                ),
              ),
              Text(
              cant ?'Cantidad: XX':'Cantidad: $_cantidad',
              style: TextStyle(

                color: cant?Colors.grey:Colors.black,

              ),
            ),


              Text(
                    presa ?'Presa: ----':'Presa: $_presa',
                    style: TextStyle(
                      fontSize: 16,
                      color: presa?Colors.grey:Colors.black,
                        fontWeight: FontWeight.bold
                    ),
                  ),

              Text(
                    salsa ?'Salsa':'$_salsa',
                    style: TextStyle(

                      color: salsa?Colors.grey:Colors.black,

                    ),
                  ),
              SizedBox(height: 15,),
              Text(
                cant ?'Precio: 27Bs': 'Precio: ${ 27 * int.parse(_cantidad)}Bs'  ,
                style: TextStyle(
                    fontSize: 17,
                    color: pollo?Colors.grey:Colors.black,
                    fontWeight: FontWeight.bold
                ),
              ),

          ],),
        )
    ],
    );
  }

  String capitalizarPrimeraLetra(String texto) {
    if (texto.isEmpty) {
      return texto;
    }
    return texto[0].toUpperCase() + texto.substring(1);
  }

  String resumen(List<Map<String, String>> total) {
    String cad = "Su pedido es: \n";
    int pago = 0;
    for (var pedido in total) {
      cad = cad + "${pedido["cantidad"]} pollo ${pedido["pollo"]} con presa ${pedido["presa"]} \n";
      pago = pago + int.parse(pedido["cantidad"]!);
    }
    cad = cad + "y el total a pagar es ${pago * 27}  bolivianos. Gracias por su preferencia.";
    _total  = [];
    return cad;
  }




}



//***************************************************


//auxiliares

String extraerObjetoEntreLlaves(String cadena) {
  int indiceInicio = cadena.indexOf('{');


  int indiceFin = -1;
  int contadorLlaves = 0;
  for (int i = indiceInicio; i < cadena.length; i++) {
    if (cadena[i] == '{') {
      contadorLlaves++;
    } else if (cadena[i] == '}') {
      contadorLlaves--;
      if (contadorLlaves == 0) {
        indiceFin = i;
        break;
      }
    }
  }

  String objetoEntreLlaves = cadena.substring(indiceInicio, indiceFin + 1);

  return objetoEntreLlaves;
}

Map<String, String> convertirCadenaAObjeto(String cadena) {
  Map<String, String> objeto = {};


  if (cadena.length == 2){return objeto;}

  cadena = cadena.replaceAll('{', '').replaceAll('}', '').trim();

  List<String> pares = cadena.split(', ');

  for (String par in pares) {
    List<String> partes = par.split(':');
    String clave = partes[0].trim();
    String valor = partes[1].trim();
    objeto[clave] = valor;
  }

  return objeto;
}

bool todosTienenValor(Map<String, String> mapa) {
  for (var valor in mapa.values) {
    if (valor.isEmpty) {
      return false;
    }
  }
  return true;
}



//***************************************************











