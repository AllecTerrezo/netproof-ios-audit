
import Foundation

extension String {

    /// Retorna a string traduzida a partir do Localizable.strings
    var localized: String {
        NSLocalizedString(self, comment: "")
    }

    /// Permite interpolação com parâmetros no futuro (ex: "%d tests")
    func localizedWith(_ arguments: CVarArg...) -> String {
        String(format: NSLocalizedString(self, comment: ""), arguments)
    }
}
