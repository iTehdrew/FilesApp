import Cocoa

final class FilesModule: BaseModule {
    let view: FilesViewController
    let presenter: FilesPresenter
    
    init(viewController: FilesViewController) {
        view = viewController
        presenter = FilesPresenter()
        presenter.view = view
        view.presenter = presenter
    }
    
    func viewController() -> NSViewController {
        return view
    }
}
