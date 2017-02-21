//
//  ViewController.swift
//  Concurrency converter
//
//  Created by Andrey Nagaev on 20.02.17.
//  Copyright © 2017 Andrey Nagaev. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var pickerFrom: UIPickerView!
    @IBOutlet weak var pickerTo: UIPickerView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var textFieldFrom: UITextField!
    @IBOutlet weak var nameLabel: UILabel!
    
    var currencies = ["RUB","USD","EUR"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.label.text = ""
        
        self.pickerTo.dataSource = self
        self.pickerFrom.dataSource = self
        
        self.pickerTo.delegate = self
        self.pickerFrom.delegate = self
        
        self.activityIndicator.hidesWhenStopped = true
        
        self.pickerTo.isHidden = true
        self.pickerFrom.isHidden = true
        self.label.isHidden = true
        
        //Получаем текущую дату, чтобы проверить актуальность списка валют в NSUserDefaults
        
        let date = NSDate()
        var dateDesc = date.description
        let index = dateDesc.index(dateDesc.startIndex, offsetBy: 10)
        dateDesc = dateDesc.substring(to: index)
        let lastDate = UserDefaults.standard.object(forKey: "lastDate") as? String
        
        if(  lastDate != dateDesc)
        {
            //Обновляем список, если дата не совпадает
            self.requestCurrencyRatesList()
        }
        else
        {
            //Получаем данные из списка и делаем видимыми основные элементы
            currencies = UserDefaults.standard.array(forKey: "currencies") as! [String]
            self.activityIndicator.stopAnimating()
            self.pickerFrom.reloadAllComponents()
            self.pickerTo.reloadAllComponents()
            self.pickerTo.isHidden = false
            self.pickerFrom.isHidden = false
            self.label.isHidden = false
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //Нажата кнопка пересчета
    @IBAction func buttonPressed(_ sender: Any) {
        self.requestCurrentCurrencyRate()
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
    
    func parseCurrencyRateResponse(data: Data?, toCurrency: String, reloadCurrencies: Bool) -> String {
        var value: String = ""
        
        do{
            let json = try JSONSerialization.jsonObject(with: data!, options:[] ) as? Dictionary<String, Any>
            
            if let parsedJSON = json {
                if let rates = parsedJSON["rates"] as? Dictionary<String, Double>{
                    if let rate = rates[toCurrency]
                    {
                        //Если передан параметр, обновляем данные в currencies
                        if(reloadCurrencies)
                        {
                            self.currencies = []
                            for(currencyName, _) in rates{
                                self.currencies.append(currencyName)
                            }
                            
                            UserDefaults.standard.set(parsedJSON["date"], forKey: "lastDate")
                        }
 
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
    
    func retrieveCurrencyRate(baseCurrency: String, toCurrency: String, reloadCurrencies: Bool, completion: @escaping(String)->Void){
        self.requestCurrencyRates(baseCurrency: baseCurrency){[weak self] (data, error) in
            var string = "No currency retrieved!"
            
            if let currentError = error
            {
                if let strongSelf = self{
                    //Выводим ошибку, в основной очереди, чтобы пользоваться приложением, надо перезайти в него
                    DispatchQueue.main.async {
                    string = currentError.localizedDescription
                    let alert = UIAlertController(title: "Ошибка!", message: string, preferredStyle: UIAlertControllerStyle.alert)
                    
                    strongSelf.present(alert, animated: true, completion: nil)
                    
                    //Прячем остальные элементы, для красоты
                    strongSelf.pickerTo.isHidden = true
                    strongSelf.pickerFrom.isHidden = true
                    strongSelf.label.isHidden = true
                    }
                }
                string = "0"
                
            } else{
                if let strongSelf = self {
                    string = strongSelf.parseCurrencyRateResponse(data: data, toCurrency: toCurrency, reloadCurrencies: reloadCurrencies)
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
        
        self.retrieveCurrencyRate(baseCurrency: baseCurrency, toCurrency: toCurrency, reloadCurrencies: false){[weak self]
            (value) in
            DispatchQueue.main.async {
                if let strongSelf = self {
                    //Считаем значение с учетом того, что написано в textField
                    let val = Double(value)
                    let mult = Double(strongSelf.textFieldFrom.text!)
                    
                    if((mult) != nil)
                    {
                        let result =  " " + baseCurrency + " в " + toCurrency
                        strongSelf.label.text = strongSelf.textFieldFrom.text! + result + " = " + (val!*mult!).description
                        strongSelf.nameLabel.text = "Основная валюта - " + baseCurrency
                    }
                    else
                    {
                        strongSelf.label.text = "0"
                    }

                    strongSelf.activityIndicator.stopAnimating()
                }
            }
        }
    }
    
    //Метод для получения списка валют, чтобы их отобразить при viewDidLoad, если их нет в памяти приложения
    func requestCurrencyRatesList(){
        self.activityIndicator.startAnimating()
        
        self.retrieveCurrencyRate(baseCurrency: "EUR", toCurrency: "USD", reloadCurrencies: true){[weak self]
            (value) in
            DispatchQueue.main.async {
                if let strongSelf = self {
                    if(value != "0")
                    {
                        //Поскольку запрос latest делается по валюте EUR, то нужно добавить эту валюту
                        strongSelf.currencies.append("EUR")
                        UserDefaults.standard.set(strongSelf.currencies, forKey: "currencies")
                        strongSelf.activityIndicator.stopAnimating()
                        strongSelf.pickerFrom.reloadAllComponents()
                        strongSelf.pickerTo.reloadAllComponents()
                        strongSelf.pickerTo.isHidden = false
                        strongSelf.pickerFrom.isHidden = false
                        strongSelf.label.isHidden = false
                    }
                }
            }
        }
    }

}




