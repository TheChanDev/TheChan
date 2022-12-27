import Foundation

protocol LinkCoder {
    func parseURL(_ url: String) -> Link?
    func getURL(for link: Link) -> String
}
