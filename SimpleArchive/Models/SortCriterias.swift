enum SortCriterias: String, CaseIterable {
    case name = "NAME"
    case creationDate = "CREATION_DATE"

    func getSortCriteriaObject() -> any SortCriteriaType {
        switch self {
        case .name:
            NameSortCriteria()
        case .creationDate:
            CreationDateSortCirteria()
        }
    }

    func getUiActionTitle() -> String {
        switch self {
        case .name:
            "Name"
        case .creationDate:
            "Creation Date"
        }
    }
}

protocol SortCriteriaType {

    var sortBy: SortCriterias { get }
    var isAscending: Bool { get set }

    func howToSort(lhs: any StorageItem, rhs: any StorageItem) -> Bool
}

struct NameSortCriteria: SortCriteriaType {

    var sortBy: SortCriterias { .name }
    var isAscending: Bool = true

    func howToSort(lhs: any StorageItem, rhs: any StorageItem) -> Bool {
        isAscending ? lhs.name < rhs.name: lhs.name > rhs.name
    }
}

struct CreationDateSortCirteria: SortCriteriaType {

    var sortBy: SortCriterias { .creationDate }
    var isAscending: Bool = true

    func howToSort(lhs: any StorageItem, rhs: any StorageItem) -> Bool {
        isAscending ? lhs.creationDate > rhs.creationDate: lhs.creationDate < rhs.creationDate
    }
}

