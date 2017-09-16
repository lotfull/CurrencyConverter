import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        if let tabBarVC = window!.rootViewController as? UITabBarController {
            if let VControllers = tabBarVC.viewControllers as? [UINavigationController] {
                let viewController = VControllers[0].topViewController as? ViewController
                if viewController != nil {
                    viewController!.managedObjectContext = managedObjectContext
                    //wordsTableVC.trendsVC = VControllers[1].topViewController as? TrendsTableVC
                } else { return true }
                if let historyTVC = VControllers[1].topViewController as? HistoryTVC {
                    historyTVC.managedObjectContext = managedObjectContext
                    historyTVC.delegate = viewController!
                }
                if let favoritesTVC = VControllers[2].topViewController as? FavoritesTVC {
                    favoritesTVC.managedObjectContext = managedObjectContext
                    favoritesTVC.delegate = viewController!

                }
            }
        }
        return true
    }
    
    // MARK: - Core Data stack
    
    lazy var managedObjectContext: NSManagedObjectContext = self.persistentContainer.viewContext
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Model")
        container.loadPersistentStores(completionHandler: { (storeDefinition, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

