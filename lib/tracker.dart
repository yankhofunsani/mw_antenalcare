import 'package:flutter/material.dart';

class Tracker extends StatefulWidget{
  const Tracker({super.key});
  @override
  _TrackerState createState() => _TrackerState();

}
class _TrackerState extends State<Tracker>{
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
      title : Text("Pregnancy Tracker", style: TextStyle(color: Colors.white)),
      backgroundColor: Colors.pinkAccent, 
      ),
      
    );  }
  
}