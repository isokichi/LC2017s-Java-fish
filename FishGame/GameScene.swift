import SpriteKit

//これを利用してCGPoint型のベクトル計算がデフォルトのように使える
func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

//32ビットOSでCGFloat型を扱えないsqrt()メソッドをプリプロセッサを使って拡張
#if !(arch(x86_64) || arch(arm64))
    func sqrt(a: CGFloat) -> CGFloat {
        return CGFloat(sqrtf(Float(a)))
    }
#endif

// CGFloat型にlength()とnormalized()メソッドを加える
extension CGPoint {
    func length() -> CGFloat {
        return sqrt(x*x + y*y)
    }
    
    func normalized() -> CGPoint {
        return self / length()
    }
}

// 乱数発生の常套手段
func random() -> CGFloat {
    return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
}
func random(min: CGFloat, max: CGFloat) -> CGFloat {
    return random() * (max - min) + min
}

// physicsBodyの設定
enum PhysicsCategory {
    static let None      : UInt32 = 0
    static let All       : UInt32 = UInt32.max
    static let Fish      : UInt32 = 0b1
    static let Food      : UInt32 = 0b10
}


class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // スプライトノードのインスタンス作成
    let fish = SKSpriteNode(imageNamed: "NEMO")
    
    
    override func didMove(to view: SKView) {
        
        //物理演算デリゲーションの設定準備
        physicsWorld.gravity = CGVector.zero
        physicsWorld.contactDelegate = self
        
        // バックグラウンドの色を白く
        backgroundColor = SKColor.white
        
        // 背景の作成
        let background = SKSpriteNode(imageNamed: "BG")
        background.position = CGPoint(x: size.width * 0.5, y: size.height * 0.4)
        background.size = CGSize(width: size.width, height: size.height * 0.8)
        background.zPosition = -100
        
        // 魚のphysicsBody
        //「physicsBody」を着せる。イメージの大きさから四角形の衝突空間を形成
        fish.physicsBody = SKPhysicsBody(rectangleOf: fish.size)
        //デフォでtrueだが一応
        fish.physicsBody?.isDynamic = true
        // ビットで立てたフラグ。UInt32なので、「0b0000 0000 0000 0000 0000 0000 0000 0001」
        fish.physicsBody?.categoryBitMask = PhysicsCategory.Fish
        // 「contactTestBitMask」は、2つの「カテゴリービットマスク」をANDオペレーションで評価して、「0」以外なら衝突が生じてSKPhysicsContactオブジェクトが作られるってことです。
        fish.physicsBody?.contactTestBitMask = PhysicsCategory.Food        // これと他のphysicsBodyのカテゴリービットマスクとANDオペレーションをして「0」以外だったら衝突がこのノードに影響を及ぼすのですが、ここで「0」を設定しているので、衝突は常に「0」で影響は出ません。
        fish.physicsBody?.collisionBitMask = PhysicsCategory.None
        //動きの速いphysicsBodyの衝突を判定する時に設定しないと素通りしてしまう可能性が出てくる
        fish.physicsBody?.usesPreciseCollisionDetection = true


        
        // ゲームシーンに追加する
        self.addChild(background)
        
        // オブジェクトの画面位置をCGPoint型で設定
        fish.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        fish.zPosition = 100
        
        // ノードオブジェクトをSceneに追加
        self.addChild(fish)
        
        self.run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run(moveFish),
                SKAction.wait(forDuration: 1.0)// 一秒ごとに呼ぶ
                ])
        ))
    }
    
    
    // 魚を動かすメソッド
    func moveFish() {

        // 魚の動く向き
        let actual_direction_x =
            random(min: CGFloat(-100.0),
                   max: CGFloat(100.0))
        let actual_direction_y =
            random(min: CGFloat(-100.0),
                   max: CGFloat(100.0))
        
        //異動先の決定
        let movepoint = fish.position + CGPoint(x:actual_direction_x ,y:actual_direction_y)
        
        // 「Action」の設定
        let actionMove =
            SKAction.move(to: movepoint,//toパラメータで動く方向指定。左端からオフスクリーンしたX軸とランダムに設定したY軸が方向
                duration: TimeInterval(1))// TimeIntervalは単なるDouble。2から4秒
        fish.run(SKAction.sequence([actionMove, ]))// sequenceメソッドはActionメソッドを数珠つなぎで実行させるメソッド
        
    }

    
    // ジェスチャーの1つ、「タッチ」を認識するメソッド
    override func touchesEnded(_ touches: Set<UITouch>,
                               with event: UIEvent?) {
        
        // Set型のelementはオプショナル型なのでguardでUITouch型のインスタンスを取りだし、タッチをした位置をCGPoint型のtouchLoacationで保持
        guard let touch = touches.first else {
            return
        }
        let touchLocation = touch.location(in: self)
        
        // タッチの位置にエサノードインスタンスを作成
        let food = SKSpriteNode(imageNamed: "FOOD")
        food.position = touchLocation
        
        // エサのPhysicsBodyの設定
        //魚と違うところは、ボディースーツを丸にしたろころ
        food.physicsBody =
            SKPhysicsBody(circleOfRadius: food.size.width/2)
        food.physicsBody?.isDynamic = true
        food.physicsBody?.categoryBitMask =
            PhysicsCategory.Food
        food.physicsBody?.contactTestBitMask =
            PhysicsCategory.Fish
        food.physicsBody?.collisionBitMask = PhysicsCategory.None
        food.physicsBody?.usesPreciseCollisionDetection = true
        
        // 水槽をタッチしても無反応
        if (touchLocation.y < size.height * 0.8) { return }
        
        // 水槽より上側をタッチしたらエサ
        self.addChild(food)
        
        // アクションを加えます。アクション終了の挙動も設定して、連続的に発生
        let actionMove = SKAction.move(to: CGPoint(x: touchLocation.x,
                                                   y: -food.size.height/2),
                                                   duration:(TimeInterval((touchLocation.y + food.size.height/2) / 100)))
        let actionMoveDone = SKAction.removeFromParent()
        food.run(SKAction.sequence([actionMove, actionMoveDone]))
        
    }
    
    //delegationメソッド
    func didBegin(_ contact: SKPhysicsContact) {
        
        //
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask <
            contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        //
        if ((firstBody.categoryBitMask &
            PhysicsCategory.Fish != 0) &&
            (secondBody.categoryBitMask &
                PhysicsCategory.Food != 0)) {
            FoodDidCollideWithFish(
                Food: firstBody.node as! SKSpriteNode,
                Fish: secondBody.node as! SKSpriteNode)
        }
        
    }
    
    //衝突たノードを消す
    func FoodDidCollideWithFish(Food: SKSpriteNode,
                                         Fish: SKSpriteNode) {
        print("Hit")
        Fish.removeFromParent()
        
        let heart = SKSpriteNode(imageNamed: "HEART")
        heart.position = CGPoint(x: fish.position.x - fish.size.width/2 - heart.size.width/2, y: fish.position.y)
        self.addChild(heart)
        let actionFadeout = SKAction.fadeOut(withDuration: 0.5)
        let actionFadeoutDone = SKAction.removeFromParent()
        heart.run(SKAction.sequence([actionFadeout, actionFadeoutDone]))

        
    }
    

}
