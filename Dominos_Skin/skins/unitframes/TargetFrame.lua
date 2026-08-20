local function SkinTargetCastbar(frame)
	hooksecurefunc(frame, "HandleInterruptOrSpellFailed", function(_, _, event)
		if ( frame.Text ) then
			if ( event == "UNIT_SPELLCAST_FAILED" ) then
				frame.Text:SetText(FAILED)
			else
				frame.Text:SetText(INTERRUPTED)
			end
		end
	end)
end

SkinTargetCastbar(TargetFrame.spellbar)
SkinTargetCastbar(FocusFrame.spellbar)

for _, frame in _G.pairs(_G.BossTargetFrameContainer.BossTargetFrames) do
	SkinTargetCastbar(frame.spellbar)
end