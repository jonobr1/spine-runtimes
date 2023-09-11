package spine.animation;

import openfl.Vector;
import spine.Event;
import spine.PathConstraint;
import spine.Skeleton;

class PathConstraintMixTimeline extends CurveTimeline {
	private static inline var ENTRIES:Int = 4;
	private static inline var ROTATE:Int = 1;
	private static inline var X:Int = 2;
	private static inline var Y:Int = 3;

	/** The index of the path constraint slot in {@link Skeleton#getPathConstraints()} that will be changed. */
	public var pathConstraintIndex:Int = 0;

	public function new(frameCount:Int, bezierCount:Int, pathConstraintIndex:Int) {
		super(frameCount, bezierCount, Vector.ofArray([Property.pathConstraintMix + "|" + pathConstraintIndex]));
		this.pathConstraintIndex = pathConstraintIndex;
	}

	public override function getFrameEntries():Int {
		return ENTRIES;
	}

	public function setFrame(frame:Int, time:Float, mixRotate:Float, mixX:Float, mixY:Float):Void {
		frame <<= 2;
		frames[frame] = time;
		frames[frame + ROTATE] = mixRotate;
		frames[frame + X] = mixX;
		frames[frame + Y] = mixY;
	}

	public override function apply(skeleton:Skeleton, lastTime:Float, time:Float, events:Vector<Event>, alpha:Float, blend:MixBlend,
			direction:MixDirection):Void {
		var constraint:PathConstraint = skeleton.pathConstraints[pathConstraintIndex];
		if (!constraint.active)
			return;

		var data:PathConstraintData;
		if (time < frames[0]) {
			data = constraint.data;
			switch (blend) {
				case MixBlend.setup:
					constraint.mixRotate = data.mixRotate;
					constraint.mixX = data.mixX;
					constraint.mixY = data.mixY;
				case MixBlend.first:
					constraint.mixRotate += (data.mixRotate - constraint.mixRotate) * alpha;
					constraint.mixX += (data.mixX - constraint.mixX) * alpha;
					constraint.mixY += (data.mixY - constraint.mixY) * alpha;
			}
			return;
		}

		var rotate:Float, x:Float, y:Float;
		var i:Int = Timeline.search(frames, time, ENTRIES);
		var curveType:Int = Std.int(curves[i >> 2]);
		switch (curveType) {
			case CurveTimeline.LINEAR:
				var before:Float = frames[i];
				rotate = frames[i + ROTATE];
				x = frames[i + X];
				y = frames[i + Y];
				var t:Float = (time - before) / (frames[i + ENTRIES] - before);
				rotate += (frames[i + ENTRIES + ROTATE] - rotate) * t;
				x += (frames[i + ENTRIES + X] - x) * t;
				y += (frames[i + ENTRIES + Y] - y) * t;
			case CurveTimeline.STEPPED:
				rotate = frames[i + ROTATE];
				x = frames[i + X];
				y = frames[i + Y];
			default:
				rotate = getBezierValue(time, i, ROTATE, curveType - CurveTimeline.BEZIER);
				x = getBezierValue(time, i, X, curveType + CurveTimeline.BEZIER_SIZE - CurveTimeline.BEZIER);
				y = getBezierValue(time, i, Y, curveType + CurveTimeline.BEZIER_SIZE * 2 - CurveTimeline.BEZIER);
		}

		if (blend == MixBlend.setup) {
			data = constraint.data;
			constraint.mixRotate = data.mixRotate + (rotate - data.mixRotate) * alpha;
			constraint.mixX = data.mixX + (x - data.mixX) * alpha;
			constraint.mixY = data.mixY + (y - data.mixY) * alpha;
		} else {
			constraint.mixRotate += (rotate - constraint.mixRotate) * alpha;
			constraint.mixX += (x - constraint.mixX) * alpha;
			constraint.mixY += (y - constraint.mixY) * alpha;
		}
	}
}
