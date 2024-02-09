class Pedido{

  String tipoPollo;
  String tipoPresa;
  String tipoSalsa;
  String tipoPago;

  Pedido(this.tipoPollo,this.tipoPresa,this.tipoSalsa,this.tipoPago);

  @override
  String toString(){
    return 'pollo:$tipoPollo- presa:$tipoPresa- salsa:$tipoSalsa- pago:$tipoPago';
  }

}


