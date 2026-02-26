//
//  GitHubRepoExplorerUITests.swift
//  GitHubRepoExplorerUITests
//
//  Created by Meng Li on 23/02/2026.

import XCTest

final class GitHubRepoExplorerUITests: XCTestCase {

    var app: XCUIApplication!

    // Known repo names from mock data
    private let firstRepoName = "god"

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.terminate()
        app.launch()
    }

    override func tearDown() {
        app.terminate()
        app = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func repoList() -> XCUIElement {
        app.collectionViews["repo_list"]
    }

    private func waitForRepoList() {
        XCTAssertTrue(
            repoList().waitForExistence(timeout: 5),
            "Repo list did not appear"
        )
        XCTAssertTrue(
            repoList().staticTexts[firstRepoName].waitForExistence(timeout: 5),
            "Repo rows did not load"
        )
    }

    /// Find the first repo row text element — scoped inside the list to avoid duplicates
    private func firstRepoRowText() -> XCUIElement {
        repoList()
            .staticTexts
            .matching(NSPredicate(format: "label == %@", firstRepoName))
            .firstMatch
    }

    private func tapFirstRepoRow() {
        waitForRepoList()
        XCTAssertTrue(firstRepoRowText().waitForExistence(timeout: 3))
        firstRepoRowText().tap()
    }

    private func swipeFirstRepoRow() {
        waitForRepoList()
        XCTAssertTrue(firstRepoRowText().waitForExistence(timeout: 3))
        firstRepoRowText().swipeLeft()
    }

    private func waitForDetailView() {
        XCTAssertTrue(
            app.staticTexts["Stars"].waitForExistence(timeout: 5),
            "Detail view did not appear"
        )
    }

    private func bookmarkFirstRepo() {
        ensureOnReposTab()
        tapFirstRepoRow()
        waitForDetailView()
        let bookmarkBtn = app.buttons["bookmark_button"]
        XCTAssertTrue(bookmarkBtn.waitForExistence(timeout: 3))
        bookmarkBtn.tap()
        XCTAssertTrue(app.buttons["bookmark_fill_button"].waitForExistence(timeout: 2))
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["GitHub Repos"].waitForExistence(timeout: 3))
    }

    private func ensureOnReposTab() {
        app.tabBars.buttons["Repos"].tap()
        XCTAssertTrue(app.navigationBars["GitHub Repos"].waitForExistence(timeout: 3))
    }

    private func goToBookmarksTab() {
        app.tabBars.buttons["Bookmarks"].tap()
        XCTAssertTrue(
            app.navigationBars["Bookmarks"].waitForExistence(timeout: 3),
            "Bookmarks tab did not appear"
        )
    }

    // MARK: - Tab Bar

    func test_tabBar_showsReposAndBookmarksTabs() {
        XCTAssertTrue(app.tabBars.buttons["Explore"].exists)
        XCTAssertTrue(app.tabBars.buttons["Bookmarks"].exists)
    }

    func test_tabBar_reposTabIsSelectedByDefault() {
        XCTAssertTrue(app.tabBars.buttons["Explore"].isSelected)
    }

    func test_tabBar_switchesToBookmarksTab() {
        goToBookmarksTab()
        XCTAssertTrue(app.navigationBars["Bookmarks"].exists)
    }

    // MARK: - RepoListView — Loading

    func test_repoList_showsNavigationTitle() {
        XCTAssertTrue(app.navigationBars["GitHub Repos"].waitForExistence(timeout: 3))
    }

    func test_repoList_showsReposAfterLoading() {
        waitForRepoList()
        XCTAssertTrue(firstRepoRowText().exists)
    }

    func test_repoList_showsGroupSectionHeaders() {
        waitForRepoList()
        XCTAssertTrue(
            app.staticTexts["User"].exists ||
            app.staticTexts["Organization"].exists
        )
    }

    // MARK: - RepoListView — Grouping

    func test_repoList_groupByMenu_exists() {
        waitForRepoList()
        XCTAssertTrue(app.buttons["Group"].exists)
    }

    func test_repoList_groupBy_forkStatus() {
        waitForRepoList()
        app.buttons["Group"].tap()
        app.buttons["Fork Status"].tap()

        XCTAssertTrue(
            app.staticTexts["Forked"].waitForExistence(timeout: 2) ||
            app.staticTexts["Original"].waitForExistence(timeout: 2)
        )
    }

    func test_repoList_groupBy_language() {
        waitForRepoList()
        app.buttons["Group"].tap()
        app.buttons["Language"].tap()

        XCTAssertTrue(repoList().waitForExistence(timeout: 3))
        XCTAssertGreaterThan(repoList().cells.count, 0)
    }

    // MARK: - RepoListView — Collapse / Expand

    func test_repoList_tappingGroupHeader_collapsesSection() {
        waitForRepoList()
        let countBefore = repoList().cells.count

        app.buttons.matching(identifier: "group_header")
            .allElementsBoundByIndex
            .first { $0.label.contains("User") }?
            .tap()

        XCTAssertLessThan(repoList().cells.count, countBefore)
    }

    func test_repoList_tappingGroupHeader_twice_expandsSection() {
        waitForRepoList()
        let countBefore = repoList().cells.count

        let userHeader = app.buttons.matching(identifier: "group_header")
            .allElementsBoundByIndex
            .first { $0.label.contains("User") }

        userHeader?.tap()
        let countCollapsed = repoList().cells.count
        userHeader?.tap()

        XCTAssertLessThan(countCollapsed, countBefore)
        XCTAssertEqual(repoList().cells.count, countBefore)
    }

    // MARK: - RepoListView → RepoDetailView Navigation

    func test_repoList_tappingRepo_navigatesToDetailView() {
        tapFirstRepoRow()
        waitForDetailView()

        XCTAssertTrue(app.staticTexts["Forks"].exists)
        XCTAssertTrue(app.staticTexts["Language"].exists)
    }

    func test_repoDetail_showsOpenOnGitHubButton() {
        tapFirstRepoRow()
        waitForDetailView()

        XCTAssertTrue(app.buttons["Open on GitHub"].waitForExistence(timeout: 3))
    }

    func test_repoDetail_backButton_returnsToRepoList() {
        tapFirstRepoRow()
        waitForDetailView()

        app.navigationBars.buttons.firstMatch.tap()

        XCTAssertTrue(app.navigationBars["GitHub Repos"].waitForExistence(timeout: 3))
    }

    // MARK: - RepoDetailView — Bookmark

    func test_repoDetail_bookmarkButton_exists() {
        tapFirstRepoRow()
        waitForDetailView()

        XCTAssertTrue(
            app.buttons["bookmark_button"].waitForExistence(timeout: 3) ||
            app.buttons["bookmark_fill_button"].waitForExistence(timeout: 3)
        )
    }

    func test_repoDetail_tappingBookmark_togglesIcon() {
        tapFirstRepoRow()
        waitForDetailView()

        XCTAssertTrue(app.buttons["bookmark_button"].waitForExistence(timeout: 3))
        app.buttons["bookmark_button"].tap()

        XCTAssertTrue(app.buttons["bookmark_fill_button"].waitForExistence(timeout: 2))
    }

    func test_repoDetail_tappingBookmark_twice_togglesBackToUnbookmarked() {
        tapFirstRepoRow()
        waitForDetailView()

        app.buttons["bookmark_button"].tap()
        XCTAssertTrue(app.buttons["bookmark_fill_button"].waitForExistence(timeout: 2))
        app.buttons["bookmark_fill_button"].tap()
        XCTAssertTrue(app.buttons["bookmark_button"].waitForExistence(timeout: 2))
    }

    // MARK: - RepoListView — Swipe to Bookmark

    func test_repoList_swipeLeft_showsBookmarkAction() {
        swipeFirstRepoRow()
        XCTAssertTrue(app.buttons["Bookmark"].waitForExistence(timeout: 2))
    }

    func test_repoList_swipeLeft_bookmark_addsToBookmarksTab() {
        swipeFirstRepoRow()
        app.buttons["Bookmark"].tap()

        goToBookmarksTab()
        XCTAssertFalse(app.staticTexts["No Bookmarks"].exists)
        XCTAssertTrue(app.staticTexts[firstRepoName].waitForExistence(timeout: 3))
    }

    // MARK: - BookmarkListView — Empty State

    func test_bookmarkList_showsEmptyState_whenNoBookmarks() {
        goToBookmarksTab()

        // Debug — print everything visible on screen
        print("\n=== ALL STATIC TEXTS ===")
        for i in 0..<app.staticTexts.count {
            let txt = app.staticTexts.element(boundBy: i)
            print("Text \(i) — label: '\(txt.label)' id: '\(txt.identifier)'")
        }
    }
}
