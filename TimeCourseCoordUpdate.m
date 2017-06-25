function TimeCourseCoordUpdate( Operation, newCoord, TimeCourseFigure, hReg )

if strcmp( 'SetCoords', Operation ),
    xjview8Clinic_spm12_timeCoursePlot( TimeCourseFigure );
end

return;