import UIKit
import CoreData

protocol showExchangeDelegate: class {
    func showExchange(_ ex: Exchange)
}

class HistoryTVC: UITableViewController {

    @IBAction func cleanHistoryButtonPressed(_ sender: UIBarButtonItem) {
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
        historyExchanges = tempExchanges
    }
    
    func filtering(ex1: Exchange) -> Bool {
        return ex1.isHistory
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return min(historyExchanges.count, 100)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryExchangeCell", for: indexPath)
        cell.textLabel?.text = historyExchanges[historyExchanges.count - indexPath.row - 1].text()
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.showExchange(historyExchanges[historyExchanges.count - indexPath.row - 1])
    }
    
    func removeData() {
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Exchange")
        let predicate = NSPredicate(format: "isFavorite == %@" ,NSNumber(booleanLiteral: false))
        fetch.predicate = predicate
        let request = NSBatchDeleteRequest(fetchRequest: fetch)
        do {
            try managedObjectContext.execute(request)
            try managedObjectContext.save()
        } catch {
            print ("There was an error")
        }
        historyExchanges = [Exchange]()
    }
    
    var delegate: showExchangeDelegate?
    var managedObjectContext: NSManagedObjectContext!
    var historyExchanges: [Exchange]!
    var tempExchanges: [Exchange]!
}
