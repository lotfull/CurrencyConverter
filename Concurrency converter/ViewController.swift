//
//  ViewController.swift
//  Concurrency converter
//
//  Created by Андрей on 20.02.17.
//  Copyright © 2017 Andrey. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var pickerFrom: UIPickerView!
    @IBOutlet weak var pickerTo: UIPickerView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let currencies = ["RUB","USD","EUR"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.label.text = "Здесь будет текст"
        
        self.pickerTo.dataSource = self
        self.pickerFrom.dataSource = self
        
        self.pickerTo.delegate = self
        self.pickerFrom.delegate = self
        
        self.activityIndicator.hidesWhenStopped = true
        
        self.requestCurrentCurrencyRate()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int
    {
        return 1;
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        if(pickerView == pickerTo)
        {
            return self.currenciesExpectBase().count
        }
        return currencies.count;
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if(pickerView == pickerTo)
        {
            return self.currenciesExpectBase()[row]
        }
        return currencies[row]
    }
    
    func requestCurrencyRates(baseCurrency: String, parseHandler: @escaping (Data?, Error?)->Void){
        let url = URL(string: "https://api.fixer.io/latest?base=" + baseCurrency);
        
        let dataTask = URLSession.shared.dataTask(with: url!){
            (dataRecieved, response, error) in
            parseHandler(dataRecieved, error)
        }
        
        dataTask.resume()
    }
    
    func parseCurrencyRateResponse(data: Data?, toCurrency: String) -> String {
        var value: String = ""
        
        do{
            let json = try JSONSerialization.jsonObject(with: data!, options:[] ) as? Dictionary<String, Any>
            
            if let parsedJSON = json {
                print("\(parsedJSON)")
                if let rates = parsedJSON["rates"] as? Dictionary<String, Double>{
                    if let rate = rates[toCurrency]
                    {
                        value = "\(rate)"
                    }
                    else{
                        value = "No rate for currency \"\(toCurrency)\" found"
                    }
                }
                else{
                    value = "No \"rates\" field found"
                }
            } else{
                value = "No JSON value parsed"
            }
        } catch {
            value = error.localizedDescription
        }
        
        return value;
    }
    
    func retrieveCurrencyRate(baseCurrency: String, toCurrency: String, completion: @escaping(String)->Void){
        self.requestCurrencyRates(baseCurrency: baseCurrency){[weak self] (data, error) in
            var string = "No currency retrieved!"
            
            if let currentError = error
            {
                string = currentError.localizedDescription
                let alert = UIAlertController(title: "Ошибка!", message: string, preferredStyle: UIAlertControllerStyle.alert)
                
                let okAction = UIAlertAction(title: "Okay", style: UIAlertActionStyle.default)
                alert.addAction(okAction)
                self!.present(alert, animated: true, completion: nil)
                string = ""
                
            } else{
                if let strongSelf = self {
                    string = strongSelf.parseCurrencyRateResponse(data: data, toCurrency: toCurrency)
                }
            }
            
            completion(string)
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        if(pickerView == pickerFrom)
        {
            self.pickerTo.reloadAllComponents()
        }
        
        self.requestCurrentCurrencyRate()
    }
    
    func currenciesExpectBase() -> [String] {
        var currenciesExpectBase = currencies
        currenciesExpectBase.remove(at: pickerFrom.selectedRow(inComponent: 0))
        
        return currenciesExpectBase
    }
    
    func requestCurrentCurrencyRate(){
        self.activityIndicator.startAnimating()
        self.label.text = ""
        
        let baseCurrencyIndex = self.pickerFrom.selectedRow(inComponent: 0)
        let toCurrencyIndex = self.pickerTo.selectedRow(inComponent: 0)
        
        let baseCurrency = self.currencies[baseCurrencyIndex]
        let toCurrency = self.currenciesExpectBase()[toCurrencyIndex]
        
        self.retrieveCurrencyRate(baseCurrency: baseCurrency, toCurrency: toCurrency){[weak self]
            (value) in
            DispatchQueue.main.async {
                if let strongSelf = self {
                    strongSelf.label.text = value
                    strongSelf.activityIndicator.stopAnimating()
                }
            }
            
        }
    }
/*
    func requestCurrencyList(baseCurrency: String, parseHandler: @escaping (Data?, Error?)->Void){
        let url = URL(string: "https://api.fixer.io/latest" + baseCurrency);
        
        let dataTask = URLSession.shared.dataTask(with: url!){
            (dataRecieved, response, error) in
            parseHandler(dataRecieved, error)
        }
        
        dataTask.resume()
    }
    
    func parseCurrencyRatesListResponse(data: Data?, toCurrency: String) -> [String] {
        var value:[String] = []
        
        do{
            let json = try JSONSerialization.jsonObject(with: data!, options:[] ) as? Dictionary<String, Any>
            
            if let parsedJSON = json {
                print("\(parsedJSON)")
                if let rates = parsedJSON["rates"] as? Dictionary<String, Double>{
                    for(currencyName, _) in rates{
                        value.append(currencyName)
                    }
                }
                else{
                    value = ["No \"rates\" field found"]
                }
            } else{
                value = ["No JSON value parsed"]
            }
        } catch {
            value = [error.localizedDescription]
        }
        
        return value;
    }
    
    func retrieveCurrencyRatesList(baseCurrency: String, toCurrency: String, completion: @escaping([String])->Void){
        self.requestCurrencyRates(baseCurrency: baseCurrency){[weak self] (data, error) in
            var string: [String] = []
            
            if let currentError = error
            {
                let alert = UIAlertController(title: "Ошибка!", message: currentError.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                
                let okAction = UIAlertAction(title: "Okay", style: UIAlertActionStyle.default)
                alert.addAction(okAction)
                self!.present(alert, animated: true, completion: nil)

            } else{
                if let strongSelf = self {
                    string = strongSelf.parseCurrencyRatesListResponse(data: data, toCurrency: toCurrency)
                }
            }
            
            completion(string)
        }
    }
 */
}




