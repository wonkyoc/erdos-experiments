#!/bin/bash

hzs=(10)
#detectors=(efficientdet-d2 efficientdet-d3 efficientdet-d4 efficientdet-d5 efficientdet-d6 efficientdet-d7)
target_speeds=(8 9 10)
file_prefix_name=ours_schedule_l
scenario=ERDOSPedestrianBehindCar

cd ${PYLOT_HOME}
dir_name=results_${file_prefix_name}
mkdir -p ${dir_name}

for run in `seq 1 5`; do
    for hz in ${hzs[@]}; do
        for target_speed in ${target_speeds[@]}; do
            file_base=${dir_name}/${file_prefix_name}_dynamic_deadlines_target_speed_${target_speed}_Hz_${hz}_run_${run}
            if [ ! -f "${PYLOT_HOME}/${file_base}.csv" ]; then
                echo "[x] Running the experiment with dynamic deadlines, target speed $target_speed"
                cd ${PYLOT_HOME}/scripts ; ./run_simulator.sh &
                sleep 10
                cd $PYLOT_HOME ; python3 pylot.py --flagfile=configs/scenarios/ours.conf --target_speed=$target_speed --log_file_name=$file_base.log --csv_log_file_name=$file_base.csv \
                    --profile_file_name=$file_base.json \
                    --obstacle_detection_model_paths=${PYLOT_HOME}/dependencies/models/obstacle_detection/efficientdet/efficientdet-d0/efficientdet-d0_frozen.pb,${PYLOT_HOME}/dependencies/models/obstacle_detection/yolox/yolox_l.pth \
                    --yolox_detection_operator --with_importance \
                    --hinted_obstacles_threshold=0.6 --small_detector_fps \
                    --obstacle_detection_model_names=efficientdet-d0,yolox_l \
                    --simulator_fps=30 --simulator_control_frequency=30 \
                    --simulator_camera_frequency=$hz --simulator_imu_frequency=$hz --simulator_localization_frequency=$hz &
                cd $SCENARIO_RUNNER_HOME ; python3 scenario_runner.py --scenario $scenario --reloadWorld --timeout 600
                echo "[x] Scenario runner finished. Killing Pylot..."
                pkill --signal 9 -f scenario_runner.py
                pkill --signal 9 pylot.py
                # Kill the simulator
                `ps aux | grep CarlaUE4 | awk '{print $2}' | head -n -1 | xargs kill -9`
                `ps aux | grep CarlaUE4 | awk '{print $2}' | tail -n -1 | xargs kill -9`
                sleep 10
            else
                echo "$file_base exists"
            fi
        done
    done
done
