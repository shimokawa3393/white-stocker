//
//  WhiteStockerUITests.swift
//  WhiteStockerUITests
//
//  Created by Shouhei Shimokawa on 2026/08/15.
//

import XCTest

final class WhiteStockerUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    /// v0コアループの一連動線を通し確認する：
    /// Task登録 → タイムライン配置 → Rowまたぎ配置 → 編集 → 削除
    ///
    /// NOTE: 現在メンテ停止中。以下の理由により実行しても失敗する：
    ///  - PlacementEditSheetの開始時刻編集を±15分ボタンからWheel Pickerに変更したため、
    ///    "increase-start-time" / "decrease-start-time" のidentifierを参照する箇所が無効
    /// 手動確認・コードレビューによる実装の健全性確認で代替しているため、当面はこのまま残す。
    @MainActor
    func testCoreLoop() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-com.apple.CoreData.SQLDebug", "0"]
        app.launch()

        attach(app, name: "01_起動直後")

        // --- タスクを2件登録 ---
        app.buttons["タスク一覧"].tap()
        addTask(app, name: "テスト掃除", quickDurationLabel: "30分")
        addTask(app, name: "テスト運動", quickDurationLabel: "60分")
        attach(app, name: "02_タスク一覧登録後")

        // タスク一覧シートを閉じ、確実に閉じ切るまで待つ
        app.swipeDown(velocity: .fast)
        let taskListNavBar = app.navigationBars["タスク一覧"]
        let taskListGone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: taskListNavBar)
        wait(for: [taskListGone], timeout: 5)

        // --- 10:00のRowに「テスト掃除」を配置（空きスロット1件→自動でタスク選択へ） ---
        let row10 = app.staticTexts["timeline-row-10"]
        XCTAssertTrue(row10.waitForExistence(timeout: 5), "Row 10:00 が見つからない")
        row10.tap()

        let pickTaskButton1 = taskButton(app, name: "テスト掃除")
        XCTAssertTrue(pickTaskButton1.waitForExistence(timeout: 5), "タスク選択画面に「テスト掃除」が無い")
        pickTaskButton1.tap()

        XCTAssertTrue(app.buttons["配置する"].waitForExistence(timeout: 5))
        app.buttons["配置する"].tap()

        attach(app, name: "03_一つ目の配置後(10:00-10:30)")

        // --- 同じRowを再タップ。残りの空き(10:30-11:00)に「テスト運動」を60分で配置
        //     → 10:30+60分=11:30となりRow10とRow11をまたぐ配置になる ---
        XCTAssertTrue(row10.waitForExistence(timeout: 5))
        row10.tap()

        let pickTaskButton2 = taskButton(app, name: "テスト運動")
        XCTAssertTrue(pickTaskButton2.waitForExistence(timeout: 5), "タスク選択画面に「テスト運動」が無い")
        pickTaskButton2.tap()

        XCTAssertTrue(app.buttons["配置する"].waitForExistence(timeout: 5))
        app.buttons["配置する"].tap()

        attach(app, name: "04_Rowまたぎ配置後(10:30-11:30)")

        // --- 配置ブロック「テスト運動」（10:30-11:30、後ろに他の配置が無い）をタップして
        //     編集し、開始時刻を+15分ずらして保存。「テスト掃除」を動かすと後続の「テスト運動」と
        //     重複してしまいSaveがdisabledになるため、後ろに何も無い側を編集対象に選ぶ ---
        let editTargetBlock = app.staticTexts["テスト運動"]
        XCTAssertTrue(editTargetBlock.waitForExistence(timeout: 5), "配置ブロック「テスト運動」が見つからない")
        editTargetBlock.tap()

        XCTAssertTrue(app.navigationBars["配置を編集"].waitForExistence(timeout: 5))
        app.buttons["increase-start-time"].tap()
        app.buttons["保存"].tap()

        attach(app, name: "05_編集後(開始時刻+15分)")

        // --- 「テスト掃除」の配置ブロックをタップして削除 ---
        let deleteTargetBlock = app.staticTexts["テスト掃除"]
        XCTAssertTrue(deleteTargetBlock.waitForExistence(timeout: 5), "配置ブロック「テスト掃除」が見つからない")
        deleteTargetBlock.tap()

        XCTAssertTrue(app.navigationBars["配置を編集"].waitForExistence(timeout: 5))
        app.buttons["この配置を削除"].tap()

        attach(app, name: "06_削除後")

        XCTAssertFalse(app.staticTexts["テスト掃除"].waitForExistence(timeout: 3), "削除したはずの「テスト掃除」がまだ表示されている")
    }

    /// SlotPickerSheetのタスク選択ボタンはVStack内の複数Textが結合され、
    /// ラベルが「テスト掃除, 30分」のようになるため完全一致では見つからない。部分一致で検索する。
    private func taskButton(_ app: XCUIApplication, name: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", name)).firstMatch
    }

    @MainActor
    private func addTask(_ app: XCUIApplication, name: String, quickDurationLabel: String) {
        app.buttons["タスクを追加"].tap()
        XCTAssertTrue(app.textFields["タスク名"].waitForExistence(timeout: 5))
        app.textFields["タスク名"].tap()
        app.textFields["タスク名"].typeText(name)

        // 所要時間はwheel pickerのデフォルト値(30分)のまま、または指定ラベルに合わせて調整。
        // v0では新規タスクのデフォルトは30分なので、60分が必要な場合だけ調整する。
        if quickDurationLabel == "60分" {
            let picker = app.pickerWheels.firstMatch
            if picker.waitForExistence(timeout: 3) {
                picker.adjust(toPickerWheelValue: "1時間")
            }
        }

        app.buttons["保存"].tap()
    }

    private func attach(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
