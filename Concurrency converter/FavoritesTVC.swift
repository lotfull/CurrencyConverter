import UIKit
import CoreData

protocol showFExchangeDelegate: class {
    func showExchange(_ ex: Exchange)
}

class FavoritesTVC: UITableViewController {

    @IBAction func cleanFavoritesButtonPressed(_ sender: UIBarButtonItem) {
        removeFavoritesData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        firstFetching()
        self.navigationItem.leftBarButtonItem = self.editButtonItem
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
    
    func removeFavoritesData() {
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
        self.tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let exchange = favoriteExchanges[indexPath.row]
            if exchange.isHistory == false {
                managedObjectContext.delete(exchange)
            } else {
                exchange.isFavorite = false
            }
            favoriteExchanges.remove(at: indexPath.row)
            tableView.reloadData()
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    var delegate: showFExchangeDelegate?
    var managedObjectContext: NSManagedObjectContext!
    var favoriteExchanges: [Exchange]!
    var tempExchanges: [Exchange]!
}
