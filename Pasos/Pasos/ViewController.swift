//
//  ViewController.swift
//  Pasos
//
//  Created by Gabriel Garces on 9/2/18.
//  Copyright © 2018 Gabriel Garces. All rights reserved.
//
// Require agregar la capability de healthKit en el Target

import UIKit
import HealthKit //importar healthkit

let healthKitStore:HKHealthStore = HKHealthStore() //crear la variable de HKHealthstore->contiene todo los datos del usuario

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //hacer redondos los botones
        Autorizar.layer.cornerRadius = 10
        Autorizar.layer.masksToBounds = true
        
        DespDatos.layer.cornerRadius = 10
        DespDatos.layer.masksToBounds = true
        
        bActPeso.layer.cornerRadius = 10
        bActPeso.layer.masksToBounds = true
        // Do any additional setup after loading the view, typically from a nib.
    }

    // botones y labels
    
    @IBOutlet weak var tPasos: UITextField!
    @IBOutlet weak var tPeso: UITextField!
    @IBOutlet weak var Autorizar: UIButton!
    @IBOutlet weak var lblSang: UILabel!
    @IBOutlet weak var lblEad: UILabel!
    @IBOutlet weak var DespDatos: UIButton!
    @IBOutlet weak var bActPeso: UIButton!
    
    
    /*Llama a la funcion donde se pide permiso al usuario para pedir los datos */
    @IBAction func getAuthorization(_ sender: Any) {
        self.authorizeHealthKit()
    }
    
    /*Funcion para desplegar los datos en los labels y, en el caso de peso, en el textfield */
    @IBAction func displayData(_ sender: Any) {
        let (edad, sangre) = self.leerSangreYCumple()
        self.lblEad.text = "\(String(describing:  edad!))"
        
        self.lblSang.text = self.traducirTipoSangre(tipoSang: (sangre?.bloodType)!)
        self.leerUltimoPeso()
        
        self.obtenerPasosDia()
    }
    
    // Llama a la funcion que actualiza el peso en Healthkit y borra el textfield
    @IBAction func actualizarPeso(_ sender: Any) {
        self.writePeso()
        self.tPeso.text = ""
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    /* Obtiene los datos de sangre y de edad, utiliza la edad guardada por el usuario y hace un calculo para obtener la edad (Int).
     Pide la info de sangre del usuario y regresa un HKBloodtype. Regresa una tupla con edad y sangre*/
    func leerSangreYCumple() -> (age:Int?, bloodtype:HKBloodTypeObject?)
    {
        var age:Int?
        var bloodtype:HKBloodTypeObject?
        var steps: HKQuantityType?
        
        
        do{
            let bd = try healthKitStore.dateOfBirthComponents() //obtener la fecha de nacimiento del usuario
            let calendar = Calendar.current  //calendario actual
            let yr = calendar.component(.year, from:Date())
            age = yr - bd.year!
            bloodtype = try healthKitStore.bloodType() //obtener tipo de sangre del usuario
            
        }catch{}
        
        return (age, bloodtype)
    }
    
    /*El tipo HKBloodType regresa la informacion de acuerdo a los diferentes tipos en un formato no amigable.
        La funcion hace la traduccion a un formato mas comun */
    
    func traducirTipoSangre(tipoSang:HKBloodType)->String
    {
        var answer:String = "";
        
        switch(tipoSang){
        case .notSet: answer = "Sin configurar"
                    break;
        case .aPositive: answer = "A+"
        break;
        case .aNegative: answer = "A-"
        break;
        case .bPositive: answer = "B+"
        break;
        case .bNegative: answer = "B-"
        break;
        case .abPositive: answer = "AB+"
        break;
        case .abNegative: answer = "AB-"
        break;
        case .oPositive: answer = "O+"
        break;
        case .oNegative: answer = "O-"
        break;
            
        }
        return answer;
    }
    
    /* Obtiene los pasos del dia y los imprime en el label */
    func obtenerPasosDia(){
        let tipoSteps = HKQuantityType.quantityType(forIdentifier: .stepCount)! //obtiene el tipo del objeto que guarda los pasos
        
        let now = Date() //fechas
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        /* se realiza el query a Healthkit para obtener los pasos realizados en un dia */
        let query = HKStatisticsQuery(quantityType: tipoSteps, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            //var stepsTotal:Double = 0.0
            guard let result = result else { //en caso de error no hacer nada e imprimir que hubo un error
                print("Error al conseguir pasos")
               return
            }
            if let sum = result.sumQuantity(){ //sumar los pasos del dia e imprimir el resultado, y desplegar en label
                    sum.doubleValue(for: HKUnit.count())
                //print("pasos: \(sum)")
                DispatchQueue.main.async(execute: { () -> Void in
                    self.tPasos.text = "\(sum)"})
                
            }
            
        }
        
        healthKitStore.execute(query)
    }



    /*Lee el ultimo peso que ha sido guardado en healthkit */
    func leerUltimoPeso()
    {
        let tipo_peso = HKSampleType.quantityType(forIdentifier: .bodyMass)! //obtener tipo de dato para el peso de healthkit
        
        /* Realizar la solicitud de los pesos guardados y tomar el ultimo */
        let query = HKSampleQuery(sampleType: tipo_peso, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, resultados, error) in
            if let resultado = resultados?.last as? HKQuantitySample{ //tomar el ultimo resultado
            print("peso : \(resultado.quantity)")
            DispatchQueue.main.async(execute: { () -> Void in
                self.tPeso.text = "\(resultado.quantity)"}) //desplegar peso en textfieeld
            }
            else{
                print("Error no se pudo obtener datos")
            }
            
        }
        healthKitStore.execute(query)
    }
    
    /*funcion para guardar el dato insertado a healthkit */
    func writePeso(){
        
        if tPeso.text?.isEmpty ?? true{
            print("Error, field is empty, do nothing!") //checar que el campo no este vacio
        }
        else{
            let w = Double(self.tPeso.text!)
            
            
            ()
            let hoy = NSDate()
            
            if let type = HKSampleType.quantityType(forIdentifier: .bodyMass){
                
                let qty = HKQuantity(unit: .gram(), doubleValue: Double(w!)) //en que unidades deseamos guardar la informacion
                let muestra = HKQuantitySample(type: type, quantity: qty, start: hoy as Date, end: hoy as Date)
                
                healthKitStore.save(muestra, withCompletion: { (success, error)  in //funcion para guardar el dato a healthkit
                    print("Guardados \(success), error \(error)")
                })
            }
        }
        
        
    }
    

    /*Pide permisos del usuario para poder acceder a los datos guardados en HealtkKit */
    func authorizeHealthKit(){
        //objetos que queremos pedir acceso para leer
        let healthKitRead : Set<HKObjectType> = [
            HKObjectType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.dateOfBirth)!,
            HKObjectType.characteristicType(forIdentifier: .bloodType)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKQuantityType.quantityType(forIdentifier: .stepCount)!
            
        ]
        //datos a los que queremos poder escribir a HealthKit
        let writeTypes : Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .bodyMass)!
        ]
        //checar que healthkit este disponible en el dispositivo
        if !HKHealthStore.isHealthDataAvailable()
        {
            print("Error occurred")
            return
        }
        //pedir la autorizacion del usuario
        healthKitStore.requestAuthorization(toShare: writeTypes, read: healthKitRead){
            (success, error) in
            if !success{
                print("Error")
            }
            print ("Read authorization granted")
        }
    }
    


}

