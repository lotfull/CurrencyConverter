//
//  FavoritesTVC.swift
//  Currency converter
//
//  Created by Kam Lotfull on 15.09.17.
//  Copyright © 2017 Andrey. All rights reserved.
//

import UIKit
import CoreData

protocol showFExchangeDelegate: class {
    func showExchange(_ ex: Exchange)
}

class FavoritesTVC: UITableViewController {

    @IBAction func cleanFavoritesButtonPressed(_ sender: UIBarButtonItem) {
        removeData()
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        firstFetching()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        firstFetching()
        tableView.reloadData()
    }
    
    func firstFetching() {
        let nameBeginsFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Exchange")
        do {
            tempExchanges = (try managedObjectContext.fetch(nameBeginsFetch) as! [Exchange])
            tempExchanges = tempExchanges.filter(filtering)
        } catch {
            fatalError("Failed to fetch words: \(error)")
        }
        favoriteExchanges = tempExchanges
    }
    
    func filtering(ex1: Exchange) -> Bool {
        return ex1.isFavorite
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return min(favoriteExchanges.count, 100)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FavoritesExchangeCell", for: indexPath)
        cell.textLabel?.text = favoriteExchanges[favoriteExchanges.count - indexPath.row - 1].text()
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.showExchange(favoriteExchanges[favoriteExchanges.count - indexPath.row - 1])
    }
    
    func removeData() {
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Exchange")
        let predicate = NSPredicate(format: "isFavorite == %@" ,NSNumber(booleanLiteral: true))
        fetch.predicate = predicate
        let request = NSBatchDeleteRequest(fetchRequest: fetch)
        do {
            try managedObjectContext.execute(request)
            try managedObjectContext.save()
        } catch {
            print ("There was an error")
        }
        favoriteExchanges = [Exchange]()
    }

    var delegate: showFExchangeDelegate?
    var managedObjectContext: NSManagedObjectContext!
    var favoriteExchanges: [Exchange]!
    var tempExchanges: [Exchange]!
}
